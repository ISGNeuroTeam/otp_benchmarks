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
SIZE_benchmark_index_many_bucket_many_parquet_file_normal=2000
SIZE_benchmark_index_many_bucket_many_parquet_file_small=80

CONFIG_FILE=$BASEDIR/$BENCHDIR/$BENCHCFG

function TestAndUnpackIndex {
  # $1 archive name
  # $2 index name
  # $3 destination path
  # $4 rewrite index
  echo "Check index"
  if [ $4 ]; then
    echo " Erasing old index '$3/$2'"
    rm -rf $3/$2
  fi
  if [ -e $3/$2 ]; then
  echo " Index $2 exist"
  echo " Calculating index size..."
  IDX_SIZE=`du -ms $3/$2 | awk '{print $1}'`
  IDX_COMPARE_SIZE=SIZE_$1
  if [ "$IDX_SIZE" -le ${!IDX_COMPARE_SIZE} ]; then
   echo " Index '$2' to small, need ${!IDX_COMPARE_SIZE} MB but exist $IDX_SIZE MB"
   NEW_RENAMED_NAME=${2}_bad_$((RANDOM%1000000))
   echo " Rename bad index to $NEW_RENAMED_NAME"
   mv $3/$2 $3/$NEW_RENAMED_NAME || exit
  fi
 fi
 if [ ! -e $3/$2 ]; then
  echo " Unpack index '$2' to '$3'"
  tar xf $1.tar.gz -C $3
 fi
}

function InstallBenchmark {
  # $1 destination path
  echo "Install Benchmark to $1/$BENCHDIR"
  mkdir -p $1/$BENCHDIR
  cp -r otp_benchmarks $1
  rm -rf otp_benchmarks
}

function ConfigureBenchmark {
  # $1 installation path
  echo "Configure benchmark"
  if [ ! -f $1 ]; then
   cp -f $1.example $1
  fi
}

function ExecuteBenchmark {
  # $1 Benchmark path
  echo "Start testing... Please wait..."
  cd $1; venv/bin/python3 benchmark.py
}

echo "Install script"
echo -ne "Select type:\n 1 - Normal pack\n 2 - Small pack (default)\n> "

read item
case "$item" in
    1) echo "Running normal tests..."
        TestAndUnpackIndex benchmark_index_single_bucket_single_parquet_file benchmark_index_single_bucket_single_parquet_file $INDEXDIR
        TestAndUnpackIndex benchmark_index_many_bucket_many_parquet_file_normal benchmark_index_many_bucket_many_parquet_file $INDEXDIR
        InstallBenchmark $BASEDIR
        ConfigureBenchmark $CONFIG_FILE
        ExecuteBenchmark $BASEDIR/$BENCHDIR
        echo "Estimated_time for query:
    1 = 1sec

  single
    2 = 1sec
    3 = 3sec
    4 = 140sec

  many
    5 = 103sec
    6 = 182sec
    7 = 157sec
    8 = 210sec"

        ;;
    *) echo "Running small tests..."
        TestAndUnpackIndex benchmark_index_single_bucket_single_parquet_file benchmark_index_single_bucket_single_parquet_file $INDEXDIR
        TestAndUnpackIndex benchmark_index_many_bucket_many_parquet_file_small benchmark_index_many_bucket_many_parquet_file $INDEXDIR true
        InstallBenchmark $BASEDIR
        ConfigureBenchmark $CONFIG_FILE
        ExecuteBenchmark $BASEDIR/$BENCHDIR
        echo "Estimated_time for query:
    1 = 1sec

  single
    2 = 1sec
    3 = 3sec
    4 = 140sec

  many
    5 = 34sec
    6 = 27sec
    7 = 24sec
    8 = 25sec"
        ;;
#    *) echo "Ничего не ввели. Выполняем действие по умолчанию..."
#        ;;
esac

echo "Repeat execute:\ncd $BASEDIR/$BENCHDIR; venv/bin/python3 benchmark.py"
