#!/bin/bash

# aici initializez directorul radacina, daca el exista cumva
# atunci il sterg (ca sa nu am informatia redundanta de data trecuta)
# eventual pot sa modific asta dupa 

if [ -d "userfsRoot" ]; then 
    rm -rf "userfsRoot"
fi

mkdir "userfsRoot"
echo "Scriptul UserFS a pornit"
echo "Apasati m pentru a primi o lista cu comenzile posibile"

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
    users=$(who | awk '{print $1}' | sort -u)
    cnt=0
    for user in $users; do 
        ((cnt++))
    done 
    echo "$cnt"
}

show_active_users() {
    users=$(who | awk '{print $1}' | sort -u)
    echo "$users"
}

count_loggedOut_users() {
    users=$(who | awk '{print $1}' | sort -u)
    cnt=0
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if ! echo "$users" | grep -q "^$curr$"; then 
            ((cnt++))
        fi
    done
    echo "$cnt"
}

show_loggedOut_users() {
    users=$(who | awk '{print $1}' | sort -u)
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if ! echo "$users" | grep -q "^$curr$"; then 
            echo "$curr"
        fi
    done
}


search_for_user() {
    target="$1"
    found=-1
    for x in "userfsRoot"/*; do 
        [ -e "$x" ] || continue 
        curr=$(basename "$x")
        if [[ "$curr" == "$1" ]]; then 

            if [ -f "$x/lastLogin" ]; then 
                ((found++))
            else
                ((found+=2))
            fi
            break 
        fi
    done

    if [[ "$found" -eq -1 ]]; then 
        echo "Utilizatorul $1 nu a fost logat pe sistem"
    else 
        if [[ "$found" -eq 0 ]]; then 
            echo "Utilizatorul $1 a fost logat pe sitem la un moment dat, dar acum este delogat"
        else 
            echo "Utilizatorul $1 este logat pe sistem"
        fi
    fi  
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

update &
upd_pid=$!
trap "kill $upd_pid" EXIT

while true; do 

    read -r -n 1 ce
    case "$ce" in 
        1)
            echo
            count_active_users
            ;;
        2)
            echo
            show_active_users
            ;;
        3)
            echo
            count_loggedOut_users
            ;;
        4)
            echo
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
        m)
            echo
            echo "Apasati 1 pentru a primi numarul de utilizatori logati pe sistem"
            echo "Apasati 2 pentru a primi o lista cu utilizatorii logati pe sistem"
            echo "Apasati 3 pentru a primi numarul cu utilizatorii delogati de pe sistem"
            echo "Apasati 4 pentru a primi o lista cu utilizatorii delogati de pe sistem"
            echo "Apasati 5 si introduceti numele unui utilizator pentru a verifica daca utilizatorul este logat, delogat sau nu a fost niciodata logat pe sistem"
            ;;

        *)
            echo "$ce nu este o comanda valida"
            ;;
    esac
done 
