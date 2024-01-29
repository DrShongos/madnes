if ! [ -d ./target ]; then
    mkdir target
fi

odin run src/ -out:target/madnes
