#!/bin/bash

timp=30
if [[ $# -gt 0 ]]; then 
    if [[ $1 =~ ^[0-9]+$ ]]; then
        timp="$1"
    else
        echo "Problemuta"
        exit 0
    fi
fi

# aici initializez directorul radacina, daca el exista cumva
# atunci il sterg (ca sa nu am informatia redundanta de data trecuta)
# eventual pot sa modific asta dupa 

if [ -d "userfsRoot" ]; then 
    rm -rf "userfsRoot"
fi

mkdir "userfsRoot"
echo "Scriptul UserFS a pornit"
echo "Tastati man pentru a vedea manualul"

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
            >"$x/procs" # lasam gol fisierul de procs 
            date > "$x/lastLogin"
        fi
    done
}

# core-ul proiectului in esenta 
# trebuie sa avem grija sa nu avem un offset intre raspunsurile la query si update 

update() {
    while true; do 
        update_data
        sleep "$timp"
    done 
}

# majoritatea functiilor de query merg cam in acelasi mod 
# vezi folderul radacina, daca avem lastlogin -> delogat
# in caz contrar activ

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
                if [[ "$2" == "-a" ]]; then 
                    cat "$x/procs"
                elif [[ "$2" == "-n" ]]; then 
                    tail -n "$3" "$x/procs"
                else 
                    tail "$x/procs"
                fi 
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
    read -r ce pp fl nr
    case "$ce" in 
        cnta)
            count_active_users
            ;;
        swa)
            show_active_users
            ;;
        cnti)
            count_loggedOut_users
            ;;
        swi)
            show_loggedOut_users
            ;;
        search)
            search_for_user "$pp"
            ;;
		last)
			last_seen_active "$pp"
			;;
        procs)
            show_last_processes "$pp" "$fl" "$nr"
            ;;
        exit)
            break 
            ;;
        man)
            echo "----------------------------------------UserFS----------------------------------------"
            echo "cnta - afiseaza numarul de utilizatori logati pe sistem"
            echo "cnti - afiseaza numarul de utilizatori delogati de pe sistem"
            echo "swa - afiseaza o lista cu utilizatorii logati pe sistem"
            echo "swi - afiseaza o lista cu utilizatorii delogati de pe sistem"
            echo "search <user> - afiseaza starea utilizatorului user (logat/delogat/nu a fost logat)"
            echo "last <user> - afiseaza ultima data cand utilizatorul user s-a delogat de pe sistem"
            echo "procs <user> [op] - afiseaza procesele utilizatorului user"
            echo " -a afiseaza toate procesele utilizatorului"
            echo " -n urmat de un numar x afiseaza ultimele x procese ale utilizatorului"
            echo "exit - opreste UserFS"
            echo "--------------------------------------------------------------------------------------"
            ;;

        *)
            echo "$ce nu este o comanda valida"
            ;;
    esac
done 
