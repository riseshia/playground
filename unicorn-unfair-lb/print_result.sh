for i in $(ls tmp/worker-*); do
  wc -l "${i}"
done
