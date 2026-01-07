#!/bin/bash

# aici initializez directorul radacina, daca el exista cumva
# atunci il sterg (ca sa nu am informatia redundanta de data trecuta)
# eventual pot sa modific asta dupa 

if [ -d "userfsRoot" ]; then 
    rm -rf "userfsRoot"
fi

mkdir "userfsRoot"
echo "Scriptul UserFS a pornit"
# trebuie sa execut functia odata la 30s 

update_data() {
    users=$(who | awk '{print $1}' | sort -u)

    # aici actualizam informatiile despre utilizatorii activi
    for user in $users; do 
        dirUser="userfsRoot/$user"

        if [ ! -d "$dirUser" ]; then 
            # avem un nou utilizator logat
            mkdir -p "$dirUser"
        fi

        ps -u "$user" > "$dirUser/procs"

        if [ -f "$dirUser/lastLogin" ]; then 
            rm "$dirUser/lastLogin"
        fi
    done

    # acum ne ocupam de utilizatorii care poate s-au delogat intre timp
    for x in "userfsRoot"/*; do 
        
        # linia asta verifica daca exista directorul cu numele x
        # daca nu pur si simplu se da skip in for 
        # de ce e importanta? 
        # daca cumva (for god knows what reason) folderul userfsRoot e gol
        # atunci o sa caute efectiv folderul userFs/*
        # lucru care nu e bine :)

        [ -e "$x" ] || continue 

        curr=$(basename "$x")
        if ! echo "$users" | grep -q "^$curr$"; then 
            >"$x/procs"
            date > "$x/lastLogin"
        fi
    done
}

update() {
    while true; do 
        update_data
        sleep 30
    done 
}

count_active_users() {
    cnt=0
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue
        if [ ! -f "$x/lastLogin" ]; then 
            ((cnt++))
        fi
    done
    echo "Sunt $cnt utilizatori logati pe sistem in momentul de fata"
}

show_active_users() {
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue
        if [ ! -f "$x/lastLogin" ]; then 
            curr=$(basename "$x")
            echo "$curr"
        fi
    done
}

count_loggedOut_users() {
    cnt=0
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue
        if [ -f "$x/lastLogin" ]; then 
            ((cnt++))
        fi
    done
    echo "Sunt $cnt utilizatori delogati de pe sistem in momentul de fata"
}

show_loggedOut_users() {
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue
        if [ -f "$x/lastLogin" ]; then 
            curr=$(basename "$x")
            echo "$curr" 
        fi
    done
}

search_for_user() {
    target="$1"
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if [[ "$curr" == "$1" ]]; then 
            if [ -f "$x/lastLogin" ]; then 
                echo "Utilizatorul $1 a fost logat pe sitem la un moment dat, dar acum este delogat"
                return 0
            else
                echo "Utilizatorul $1 este logat pe sistem"
                return 0
            fi
            break 
        fi
    done

    echo "Utilizatorul $1 nu a fost logat pe sistem"
}

last_seen_active() {
	target=$1
	for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if [[ "$curr" == "$1" ]]; then 

            if [ -f "$x/lastLogin" ]; then 
				cat "$x/lastLogin"
				return 0
            else
				echo "Utilizatorul $curr este activ"
				return 0	
            fi
            break 
        fi
    done
	echo "Utilizatorul $target nu a fost logat pe sistem"
}

show_last_processes() {
    target=$1
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if [[ "$curr" == "$1" ]]; then 
            if [ -f "$x/lastLogin" ]; then 
                echo "Utilizatorul $1 nu este logat pe sistem momentan"
                return 0
            else 
                tail -n 10 "$x/procs"
                return 0
            fi
        fi
    done
    echo "Utilizatorul $1 nu a fost logat pe sistem"
}

update &
upd_pid=$!
trap "kill $upd_pid" EXIT

while true; do 
    read -r -n 5 ce
    case "$ce" in 
        1)
            count_active_users
            ;;
        2)
            show_active_users
            ;;
        3)
            count_loggedOut_users
            ;;
        4)
            show_loggedOut_users
            ;;
        5)
            read pp
            search_for_user "$pp"
            ;;
		6)
			read pp 
			last_seen_active "$pp"
			;;
        7)
            read pp
            show_last_processes "$pp"
            ;;
        exit)
            break 
            ;;
        man)
            echo "aici ar trebui sa fie un manual, il punem dupa"
            ;;

        *)
            echo "$ce nu este o comanda valida"
            ;;
    esac
done 
