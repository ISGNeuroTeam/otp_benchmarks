#!/bin/sh

#TODO
# search OT Platform home dir
# search indexes dir
# search flow dir
# unpack buckets
# add new indexes to allow index in rest
# testing
# clean
# show result


BASEDIR=/opt/otp
BENCHDIR=otp_benchmarks
BENCHCFG=benchmark.cfg

INDEXDIR=/opt/otp/indexes
IDX1=benchmark_index_single_bucket_single_parquet_file
SIZE_benchmark_index_single_bucket_single_parquet_file=220
IDX2=benchmark_index_many_bucket_many_parquet_file
SIZE_benchmark_index_many_bucket_many_parquet_file=2300

CONFIG_FILE=$BASEDIR/$BENCHDIR/$BENCHCFG


echo "Install script"

mkdir -p $BASEDIR/$BENCHDIR
cp -r otp_benchmarks $BASEDIR
rm -rf otp_benchmarks

if [ ! -f $CONFIG_FILE ]; then
 cp $CONFIG_FILE.example $CONFIG_FILE
fi

for IDX in $IDX1 $IDX2; do
 echo "Test index '$IDX'"

 if [ -e $INDEXDIR/$IDX ]; then
  IDX_SIZE=`du -ms $INDEXDIR/$IDX | awk '{print $1}'`
  IDX_COMPARE_SIZE=SIZE_$IDX
  if [ "$IDX_SIZE" -le ${!IDX_COMPARE_SIZE} ]; then
   echo "Index '$IDX' to small, need ${!IDX_COMPARE_SIZE} MB but exist $IDX_SIZE MB"
   echo "Recovery index"
   mv $INDEXDIR/$IDX $INDEXDIR/${IDX}_bad || exit
  fi
 fi

 if [ ! -e $INDEXDIR/$IDX ]; then
  echo "Unpack index '$IDX'"
  tar xf $IDX.tar.gz -C $INDEXDIR
 fi
done



    
echo "Start testing... Please wait..."
cd $BASEDIR/$BENCHDIR; venv/bin/python3 benchmark.py

