#!/bin/sh
# nvim's Claude Code link (plugins/ai.lua, lua/ai.lua) in a real UI (a scratch tmux).
# Stubs of the fish functions `claude` and `claude-team` (the panes' fish gets a
# scratch XDG_CONFIG_HOME) record how the keys start Claude: account, port, folder. A
# stand-in for Claude (Python, stdlib) connects to nvim the way Claude does: the lock
# file, its token, a WebSocket. It gets the selection and the sends, and proposes
# edits that the keys accept or reject. Real Claude never starts: the test stops
# before the keys if fish would find the real functions. The lock file goes into a
# scratch CLAUDE_CONFIG_DIR, not ~/.claude/ide.
# Run: sh tests/nvim-ai.sh
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
tm() { tmux -L nvim-ai -f /dev/null "$@"; }
trap 'kill $fake 2>/dev/null; tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fake=
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

mkdir -p "$tmp/fish/fish/functions" "$tmp/claude" "$tmp/proj"
for f in claude claude-team; do
    printf 'function %s\n    echo %s $CLAUDE_CODE_SSE_PORT $PWD >>%s/started\n    sleep 300\nend\n' \
        $f $f "$tmp" >"$tmp/fish/fish/functions/$f.fish"
done
cd "$tmp/proj" && git init -q && printf 'line %s\n' 1 2 3 4 5 6 >notes.txt

# the stand-in: logs what nvim sends (one JSON per line) and, when a file named
# diff-N appears, proposes notes.txt with line 1 changed to its contents
cat >"$tmp/claude.py" <<'EOF'
import base64, glob, json, os, select, socket, struct, sys
tmp = sys.argv[1]
lock = glob.glob(tmp + "/claude/ide/*.lock")[0]
port, token = int(os.path.basename(lock)[:-5]), json.load(open(lock))["authToken"]
s = socket.create_connection(("127.0.0.1", port))
key = base64.b64encode(os.urandom(16)).decode()
s.sendall((f"GET / HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\n"
           f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n"
           f"x-claude-code-ide-authorization: {token}\r\n\r\n").encode())
buf = b""
while b"\r\n\r\n" not in buf:
    buf += s.recv(4096)
head, buf = buf.split(b"\r\n\r\n", 1)
log = open(tmp + "/claude.log", "a", buffering=1)
log.write(json.dumps({"handshake": head.split(b"\r\n")[0].decode()}) + "\n")

def send(obj, opcode=1):
    data = obj if isinstance(obj, bytes) else json.dumps(obj).encode()
    mask, n = os.urandom(4), len(data)
    size = bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n)
    s.sendall(bytes([0x80 | opcode]) + size + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def frames():
    global buf
    while len(buf) >= 2:
        n, at = buf[1] & 0x7F, 2
        if n == 126:
            n, at = struct.unpack(">H", buf[2:4])[0], 4
        elif n == 127:
            n, at = struct.unpack(">Q", buf[2:10])[0], 10
        if len(buf) < at + n:
            return
        opcode, data, buf = buf[0] & 0x0F, buf[at:at + n], buf[at + n:]
        if opcode == 9:
            send(data, 10)
        elif opcode == 1:
            log.write(data.decode() + "\n")
            answer(json.loads(data))

# as Claude does once a diff is answered: write the accepted text, close the tab
def answer(msg):
    tab = pending.pop(msg.get("id"), None)
    if not tab:
        return
    texts = [c["text"] for c in msg["result"]["content"]]
    if texts[0] == "FILE_SAVED":
        open(tmp + "/proj/notes.txt", "w").write(texts[1])
    send({"jsonrpc": "2.0", "id": 100 + msg["id"], "method": "tools/call",
          "params": {"name": "close_tab", "arguments": {"tab_name": tab}}})

send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}})
proposed, pending = 0, {}
while True:
    if select.select([s], [], [], 0.2)[0]:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        frames()
    if os.path.exists(f"{tmp}/diff-{proposed + 1}"):
        proposed += 1
        line = open(f"{tmp}/diff-{proposed}").read().strip()
        path = tmp + "/proj/notes.txt"
        new = line + "\n" + "".join(open(path).readlines()[1:])
        send({"jsonrpc": "2.0", "id": 10 + proposed, "method": "tools/call", "params": {
            "name": "openDiff", "arguments": {"old_file_path": path, "new_file_path": path,
            "new_file_contents": new, "tab_name": f"✻ [Claude Code] notes.txt ({proposed}) ⧉"}}})
        pending[10 + proposed] = f"✻ [Claude Code] notes.txt ({proposed}) ⧉"
EOF

tm new-session -d -x 200 -y 40 -c "$PWD" -e "XDG_CONFIG_HOME=$tmp/fish" -e "CLAUDE_CONFIG_DIR=$tmp/claude" \
    "sleep 0.5; env XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config} $nvim notes.txt"
nv=$(tm display -p -t 0 '#{pane_id}')
sleep 3 # nvim, then VeryLazy starts the server
keys() { tm send-keys -t "$nv" "$@"; sleep 0.6; }
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t "$nv" Escape
    sleep 0.2
    tm send-keys -t "$nv" ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}
active() { tm display -p '#{pane_id}'; }
tagged() { tm list-panes -F '#{pane_id} #{@claude}' | awk -v a="$1" '$2 == a { print $1 }'; }
got() { grep -c "$1" "$tmp/claude.log" 2>/dev/null; }

tm new-window -d "fish -c 'functions --details claude; functions --details claude-team' >$tmp/which"
sleep 0.5
if [ "$(cat "$tmp/which")" != "$(printf '%s\n' "$tmp/fish/fish/functions/claude.fish" "$tmp/fish/fish/functions/claude-team.fish")" ]; then
    echo "STOP: the panes' fish would start the real claude"
    exit 1
fi

lock=$(ls "$tmp/claude/ide/"*.lock 2>/dev/null)
port=$(basename "${lock:-none}" .lock)
check "the server runs, its lock file in CLAUDE_CONFIG_DIR" [ -n "$lock" ]
check "  names nvim's folder" grep -q "\"$PWD\"" "$lock"

keys ' ac'
sleep 1
check "<leader>ac: Claude in a new pane, focused" [ "$(active)" = "$(tagged claude)" ]
check "  the personal account, the port, nvim's folder" \
    [ "$(sed -n 1p "$tmp/started")" = "claude $port $PWD" ]
tm select-pane -t "$nv"
keys ' ac'
check "  again: jumps to it, no second pane" [ "$(active)" = "$(tagged claude)" -a "$(tm list-panes | wc -l)" -eq 2 ]
tm select-pane -t "$nv"
keys ' aC'
sleep 1
check "<leader>aC: the team account in its own pane" \
    [ "$(active)" = "$(tagged claude-team)" -a "$(sed -n 2p "$tmp/started")" = "claude-team $port $PWD" ]

python3 "$tmp/claude.py" "$tmp" &
fake=$!
sleep 1
check "Claude connects with the lock file's token" grep -q '101 Switching' "$tmp/claude.log"
tm select-pane -t "$nv"
keys 3G
sleep 0.5
check "  it sees the cursor's file" sh -c "grep selection_changed '$tmp/claude.log' | grep -q notes.txt"
keys V j ' as'
sleep 0.5
check "<leader>as: the lines go as a mention (0-based 2-3)" \
    sh -c "grep at_mentioned '$tmp/claude.log' | grep notes.txt | grep '\"lineStart\":2' | grep -q '\"lineEnd\":3'"
check "  and the cursor jumps to the last key's Claude" [ "$(active)" = "$(tagged claude-team)" ]

tm select-pane -t "$nv"
echo 'line one' >"$tmp/diff-1"
sleep 1.5
check "an edit opens as a diff" [ "$(probe '#vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(0))')" = 2 ]
keys ' ad'
sleep 1
check "<leader>ad: rejected" [ "$(got DIFF_REJECTED)" -eq 1 ]
echo 'line ONE' >"$tmp/diff-2"
sleep 1.5
keys ' aa'
sleep 1
check "<leader>aa: accepted, Claude gets the text" sh -c "grep FILE_SAVED '$tmp/claude.log' | grep -q 'line ONE'"
check "  the diff is closed, the file has the edit" [ "$(probe '#vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(0))')" = 0 -a "$(probe "vim.cmd.checktime() and vim.fn.getline(1)")" = 'line ONE' ]
check "nothing in ~/.claude/ide is this nvim's" sh -c "! grep -qs '\"$PWD\"' ~/.claude/ide/*.lock"

if [ $fails -gt 0 ]; then
    tail -4 "$tmp/claude.log" | cut -c1-300
    probe "vim.fn.execute('messages')" | tail -5
    echo "$fails failed"
    exit 1
fi
echo "all passed"
