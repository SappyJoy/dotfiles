function print_motd
	set datafile $argv
	set wednesday (date +"%w" | string collect)
	if [ $wednesday = "3" ]
            fortune $datafile | cowsay -f small-frogs-wednesday -W 80
        else
            fortune $datafile | cowsay -W 80
    	end | lolcat
end
