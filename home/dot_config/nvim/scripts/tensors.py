#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["numpy", "h5py"]
# ///
"""Arrays in a file, as text: name, shape, dtype, size; min, max, mean and NaNs for
.npy and .npz. Reads npy, npz, safetensors, PyTorch checkpoints (zip), pickle, HDF5.

Never runs code from the file: a pickle (.pkl, and the data.pkl inside a .pt) can
hold any program, so it goes through an unpickler that builds nothing but stand-ins
and records what the tensors and arrays would be.
Usage: tensors.py FILE (the nvim documents module runs it with uv)."""

import io
import json
import os
import pickle
import struct
import sys
import zipfile

import numpy as np

ELEMENTS_FOR_FULL_STATS = 200_000_000  # above: stats from an evenly spaced sample


def human(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024


def table(rows):
    """rows: (name, shape, dtype, bytes) -> aligned lines"""
    rows = [("name", "shape", "dtype", "size")] + [
        (n, "[" + ", ".join(map(str, s)) + "]", str(d), human(b) if b is not None else "?")
        for n, s, d, b in rows
    ]
    widths = [max(len(r[i]) for r in rows) for i in range(4)]
    return ["  ".join(c.ljust(w) for c, w in zip(r, widths)).rstrip() for r in rows]


def stats(a):
    if a.dtype.kind not in "fiub" or a.size == 0:
        return None
    flat = a.reshape(-1)
    note = ""
    if flat.size > ELEMENTS_FOR_FULL_STATS:
        flat = flat[:: flat.size // ELEMENTS_FOR_FULL_STATS + 1]
        note = "  (from a sample)"
    flat = flat.astype(np.float64) if flat.dtype.kind == "b" else flat
    nan = int(np.isnan(flat).sum()) if flat.dtype.kind == "f" else 0
    return (
        f"  min {np.nanmin(flat):.6g}  max {np.nanmax(flat):.6g}  "
        f"mean {np.nanmean(flat):.6g}  NaN {nan}{note}"
    )


def npy(path):
    a = np.load(path, mmap_mode="r", allow_pickle=False)
    out = table([(os.path.basename(path), a.shape, a.dtype, a.nbytes)])
    s = stats(a)
    return out + ([s] if s else [])


def npz(path):
    out = []
    with np.load(path, allow_pickle=False) as z:
        rows, extra = [], []
        for name in z.files:
            a = z[name]
            rows.append((name, a.shape, a.dtype, a.nbytes))
            s = stats(a)
            if s:
                extra.append(f"{name}:{s}")
        out = [f"{len(rows)} arrays", ""] + table(rows) + [""] + extra
    return out


def safetensors(path):
    with open(path, "rb") as f:
        (n,) = struct.unpack("<Q", f.read(8))
        header = json.loads(f.read(n))
    meta = header.pop("__metadata__", None)
    rows = [
        (k, v["shape"], v["dtype"], v["data_offsets"][1] - v["data_offsets"][0])
        for k, v in header.items()
    ]
    out = [f"{len(rows)} tensors", ""] + table(rows)
    if meta:
        out += ["", "metadata:"] + [f"  {k}: {v}" for k, v in meta.items()]
    return out


# --- pickle, without running it ---------------------------------------------------


class Stub:
    """Anything a pickle asks to build: remembers what, never runs it. Each name the
    pickle asks for gets an empty subclass (pickle's NEWOBJ wants a real class)."""

    qualname = "?"

    def __new__(cls, *args, **kwargs):
        obj = object.__new__(cls)
        obj.args, obj.state = args, None
        return obj

    def __init__(self, *args, **kwargs):
        pass

    def __setstate__(self, state):
        self.state = state

    def __repr__(self):
        return f"<{self.qualname}>"


_stub_classes = {}


def stub_class(qualname):
    if qualname not in _stub_classes:
        _stub_classes[qualname] = type(qualname.rsplit(".", 1)[-1], (Stub,), {"qualname": qualname})
    return _stub_classes[qualname]


class Tensor:
    def __init__(self, shape, dtype):
        self.shape, self.dtype = tuple(shape), dtype


TORCH_DTYPES = {
    "FloatStorage": ("float32", 4), "DoubleStorage": ("float64", 8),
    "HalfStorage": ("float16", 2), "BFloat16Storage": ("bfloat16", 2),
    "LongStorage": ("int64", 8), "IntStorage": ("int32", 4),
    "ShortStorage": ("int16", 2), "CharStorage": ("int8", 1),
    "ByteStorage": ("uint8", 1), "BoolStorage": ("bool", 1),
}


def rebuild_tensor(storage, offset, size, *rest):
    dtype = storage[0] if isinstance(storage, tuple) else "?"
    return Tensor(size, dtype)


class SafeUnpickler(pickle.Unpickler):
    def find_class(self, module, name):
        q = f"{module}.{name}"
        if q in ("collections.OrderedDict", "builtins.dict", "builtins.list", "builtins.set",
                 "builtins.tuple", "builtins.frozenset"):
            return {"collections.OrderedDict": dict, "builtins.dict": dict,
                    "builtins.list": list, "builtins.set": set, "builtins.tuple": tuple,
                    "builtins.frozenset": frozenset}[q]
        if name in ("_rebuild_tensor_v2", "_rebuild_tensor"):
            return rebuild_tensor
        if module == "torch" and name in TORCH_DTYPES:
            return ("storage", name)
        if module == "torch" and name in ("Size",):
            return tuple
        return stub_class(q)

    def persistent_load(self, pid):
        # torch zip checkpoints: ('storage', StorageType, key, location, numel)
        if isinstance(pid, tuple) and pid and pid[0] == "storage":
            kind = pid[1]
            name = kind[1] if isinstance(kind, tuple) else getattr(kind, "qualname", str(kind))
            name = name.rsplit(".", 1)[-1]
            return (TORCH_DTYPES.get(name, (name, None))[0],)
        return stub_class("persistent")(pid)


def ndarray_info(stub):
    """numpy arrays in a pickle: __setstate__((version, shape, dtype, fortran, data))"""
    st = stub.state
    if isinstance(st, tuple) and len(st) >= 3:
        shape, dtype = st[1], st[2]
        d = dtype.args[0] if isinstance(dtype, Stub) and dtype.args else dtype
        return shape, d
    return None


def walk(obj, prefix, rows, other, depth=0):
    if len(rows) + len(other) > 5000:
        return
    if isinstance(obj, Tensor):
        size = TORCH_DTYPES_BYTES.get(obj.dtype)
        numel = int(np.prod(obj.shape)) if obj.shape else 1
        rows.append((prefix or "(tensor)", obj.shape, obj.dtype, numel * size if size else None))
    elif isinstance(obj, Stub) and obj.qualname in ("numpy.core.multiarray._reconstruct",
                                                    "numpy._core.multiarray._reconstruct",
                                                    "numpy.ndarray"):
        info = ndarray_info(obj)
        if info:
            shape, dtype = info
            try:
                nbytes = int(np.prod(shape)) * np.dtype(str(dtype)).itemsize
            except Exception:
                nbytes = None
            rows.append((prefix or "(array)", tuple(shape), dtype, nbytes))
        else:
            other.append(f"{prefix}: numpy array")
    elif isinstance(obj, dict):
        if depth == 0 and not obj:
            other.append("(empty dict)")
        for k, v in obj.items():
            walk(v, f"{prefix}.{k}" if prefix else str(k), rows, other, depth + 1)
    elif isinstance(obj, (list, tuple)) and depth < 6:
        if len(obj) > 50 and not any(isinstance(x, (Tensor, Stub, dict)) for x in obj[:50]):
            other.append(f"{prefix or '(top)'}: {type(obj).__name__} of {len(obj)}")
            return
        for i, v in enumerate(obj):
            walk(v, f"{prefix}[{i}]", rows, other, depth + 1)
    elif isinstance(obj, Stub):
        other.append(f"{prefix or '(top)'}: {obj.qualname}")
        if isinstance(obj.state, dict):
            walk(obj.state, prefix, rows, other, depth + 1)
    else:
        text = repr(obj)
        other.append(f"{prefix or '(top)'}: {text[:80] + '…' if len(text) > 80 else text}")


TORCH_DTYPES_BYTES = {v[0]: v[1] for v in TORCH_DTYPES.values()}


def unpickled(data):
    obj = SafeUnpickler(io.BytesIO(data)).load()
    rows, other = [], []
    walk(obj, "", rows, other)
    out = [f"{len(rows)} tensors / arrays"] if rows else []
    if rows:
        out += [""] + table(rows)
    if other:
        out += ["", "other values:"] + [f"  {o}" for o in other[:200]]
    return out


def torch_checkpoint(path):
    with zipfile.ZipFile(path) as z:
        pkl = next(n for n in z.namelist() if n.endswith("data.pkl"))
        return ["PyTorch checkpoint (read without torch, no code run)", ""] + unpickled(z.read(pkl))


def pickle_file(path):
    with open(path, "rb") as f:
        data = f.read()
    return ["pickle (read without running it: classes are shown by name)", ""] + unpickled(data)


def hdf5(path):
    import h5py

    rows, extra = [], []

    def visit(name, item):
        if isinstance(item, h5py.Dataset):
            rows.append((name, item.shape, item.dtype, item.size * item.dtype.itemsize))
            if item.dtype.kind in "fiu" and 0 < item.size <= 50_000_000:
                s = stats(item[()])
                if s:
                    extra.append(f"{name}:{s}")

    with h5py.File(path, "r") as f:
        f.visititems(visit)
        attrs = dict(f.attrs)
    out = [f"{len(rows)} datasets", ""] + table(rows) + ([""] + extra if extra else [])
    if attrs:
        out += ["", "attributes:"] + [f"  {k}: {v}" for k, v in attrs.items()]
    return out


def main(path):
    with open(path, "rb") as f:
        head = f.read(8)
    ext = os.path.splitext(path)[1].lower()
    if head.startswith(b"\x93NUMPY"):
        body = npy(path)
    elif ext == ".npz":
        body = npz(path)
    elif ext == ".safetensors":
        body = safetensors(path)
    elif head.startswith(b"\x89HDF"):
        body = hdf5(path)
    elif head.startswith(b"PK") and zipfile.is_zipfile(path):
        body = torch_checkpoint(path)
    elif head.startswith(b"\x80"):
        body = pickle_file(path)
    else:
        sys.exit(f"{path}: not an array format this reader knows")
    print(f"{os.path.basename(path)}   {human(os.path.getsize(path))}")
    print()
    print("\n".join(body))


if __name__ == "__main__":
    main(sys.argv[1])
