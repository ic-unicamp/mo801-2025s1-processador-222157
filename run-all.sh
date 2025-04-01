
for a in `seq -w 00 99`; do
  if [ -f test/teste$a.mem ]; then
    printf "Teste $a: "
    ./run-local.sh $a
  fi
done
