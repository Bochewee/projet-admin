#!/bin/bash

# Fonction pour ajouter un utilisateur
ajouter_utilisateur() {
  read -p "Entrez le nom d'utilisateur: " username
  if [[ -z "$username" ]]; then
    echo "Le nom d'utilisateur est vide."
    return 1
  fi

  read -p "Entrez le chemin du dossier utilisateur: " userdir
  if [[ -z "$userdir" ]]; then
    echo "Le chemin du dossier utilisateur est vide."
    return 2
  elif [[ -d "$userdir" ]]; then
    echo "Le chemin du dossier utilisateur existe déjà."
    return 3
  fi

  read -p "Entrez la date d'expiration (YYYY-MM-DD): " expdate
  if [[ -z "$expdate" ]]; then
    echo "La date d'expiration est vide."
    return 4
  elif [[ "$expdate" < $(date +%F) ]]; then
    echo "La date d'expiration est antérieure à aujourd'hui."
    return 5
  fi

  read -p "Entrez le mot de passe: " -s password
  echo
  read -p "Entrez le Shell: " shell
  if [[ -z "$shell" ]]; then
    echo "Le Shell est vide."
    return 6
  elif ! which "$shell" > /dev/null; then
    echo "Le Shell n'est pas installé."
    # Bonus: Installation du Shell si inexistant
    if sudo apt-get install -y "$shell"; then
      echo "Shell '$shell' installé avec succès."
    else
      return 7
    fi
  fi

  read -p "Entrez l'identifiant (UID): " uid
  if id "$uid" &>/dev/null; then
    echo "L'identifiant (UID) existe déjà."
    return 8
  fi

  # Création de l'utilisateur
  sudo useradd -m -d "$userdir" -e "$expdate" -s "$shell" -u "$uid" "$username"
  echo "$username:$password" | sudo chpasswd
}
# Fonction pour modifier un utilisateur
modifier_utilisateur() {
  read -p "Entrez le nom d'utilisateur actuel: " old_username
  if ! id "$old_username" &>/dev/null; then
    echo "L'utilisateur n'existe pas."
    return 1
  fi

  read -p "Entrez le nouveau nom d'utilisateur: " new_username
  read -p "Entrez le nouveau chemin du dossier utilisateur: " new_userdir
  read -p "Entrez la nouvelle date d'expiration (YYYY-MM-DD): " new_expdate
  read -p "Entrez le nouveau mot de passe: " -s new_password
  echo
  read -p "Entrez le nouveau Shell: " new_shell
  read -p "Entrez le nouvel identifiant (UID): " new_uid

  # Vérification des entrées
  if [[ -z "$new_username" ]]; then
    echo "Le nom d'utilisateur est vide."
    return 2
  fi

  if [[ -z "$new_userdir" ]]; then
    echo "Le chemin du dossier utilisateur est vide."
    return 3
  elif [[ ! -d "$new_userdir" ]]; then
    echo "Le nouveau chemin du dossier utilisateur n'existe pas."
    return 4
  fi

  if [[ -z "$new_expdate" ]]; then
    echo "La date d'expiration est vide."
    return 5
  elif [[ "$new_expdate" < $(date +%F) ]]; then
    echo "La date d'expiration est antérieure à aujourd'hui."
    return 6
  fi

  if [[ -z "$new_shell" ]]; then
    echo "Le Shell est vide."
    return 7
  elif ! which "$new_shell" > /dev/null; then
    echo "Le Shell n'est pas installé."
    return 8
  fi

  if [[ -z "$new_uid" ]]; then
    echo "L'UID est vide."
    return 9
  elif id "$new_uid" &>/dev/null; then
    echo "L'UID existe déjà."
    return 10
  fi

  # Modification de l'utilisateur
  sudo usermod -l "$new_username" "$old_username"
  sudo usermod -d "$new_userdir" -m "$new_username"
  sudo usermod -e "$new_expdate" "$new_username"
  echo "$new_username:$new_password" | sudo chpasswd
  sudo usermod -s "$new_shell" "$new_username"
  sudo usermod -u "$new_uid" "$new_username"
}

# Fonction pour supprimer un utilisateur
supprimer_utilisateur() {
  read -p "Entrez le nom de l'utilisateur à supprimer: " username
  if id "$username" &>/dev/null; then
    read -p "Supprimer le dossier utilisateur (oui/non) ? " suppr_dossier
    if [[ "$suppr_dossier" == "oui" ]]; then
      sudo userdel -r "$username"
    else
      sudo userdel "$username"
    fi
  else
    echo "L'utilisateur n'existe pas."
    return 9
  fi
}

# Affichage du menu
PS3='Choisissez une option: '
options=("Ajouter un utilisateur" "Modifier un utilisateur" "Supprimer un utilisateur" "Sortie")
select opt in "${options[@]}"
do
  case $opt in
    "Ajouter un utilisateur")
      ajouter_utilisateur
      ;;
    "Modifier un utilisateur")
      modifier_utilisateur
      ;;
    "Supprimer un utilisateur")
      supprimer_utilisateur
      ;;
    "Sortie")
      break
      ;;
    *) echo "Option invalide $REPLY";;
  esac
done

