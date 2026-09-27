function vid_comp720 --description 'Compress a video to 720p H.264: vid_comp720 in.mp4 [out.mp4]'
    if not set -q argv[1]
        echo "Usage: vid_comp720 input.mp4 [output_720z.mp4]"
        return 1
    end
    set -l input $argv[1]
    set -l output $argv[2]
    # Default output: the input name with _720z before the extension
    set -q output[1]; or set output (string replace -r '(.*)\.([^.]+)$' '$1_720z.$2' $input)
    ffmpeg -i $input -s hd720 -vcodec libx264 -crf 28 -preset medium -threads 16 $output
end
