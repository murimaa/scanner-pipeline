#!/bin/bash

# Tarkistaa, että lähdehakemisto on annettu
if [ -z "$1" ]; then
    echo "Käyttö: $0 lähdehakemisto"
    exit 1
fi

# Tarkistaa, että kohdehakemisto on olemassa
if [ ! -d "$1" ]; then
    echo "Lähdehakemistoa ei löydy: $1"
    exit 1
fi
sleep 1
# Kopioi kaikki tiedostot ja alihakemistot argumentin hakemistosta nykyiseen
cp -r "$1"/* .

echo "Tiedostot kopioitu onnistuneesti hakemistoon $1"
echo "Prosessointi suoritettu."
