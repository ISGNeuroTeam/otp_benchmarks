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
SIZE_benchmark_index_single_bucket_single_parquet_file.tar.gz=220
IDX2=benchmark_index_many_bucket_many_parquet_file
SIZE_benchmark_index_many_bucket_many_parquet_file=2300

CONFIG_FILE=$BASEDIR/$BENCHDIR/$BENCHCFG

function TestAndUnpackIndex {
  # $1 index name
  # $2 destination path
#          TestAndUnpackIndex benchmark_index_single_bucket_single_parquet_file.tar.gz benchmark_index_single_bucket_single_parquet_file $INDEXDIR

  echo "Check index"
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
 echo " Unpack index '$2' to '$3'"
 tar xf $2.tar.gz -C $3
}

function InstallBenchmark {
  # $1 destination path
  echo "Install Benchmark to $1/$BENCHDIR"
  mkdir -p $1/$BENCHDIR
  cp -r otp_benchmarks $1
  rm -rf otp_benchmarks
}

function ConfigureSmallBenchmark {
  # $1 installation path
  echo "Configure benchmark to small mode"
  echo "cfg small $1 $2 $3"
  #!!!!!!!!!!!!!!!!!
}

function ConfigureNormalBenchmark {
  # $1 installation path
  echo "Configure benchmark to normal mode"
  #!!!!!!!!!!!!!!!!!!!!!!!
  cp -f $CONFIG_FILE.example $CONFIG_FILE
}

function ExecuteBenchmark {
  # $1 Benchmark path
  echo "Start testing... Please wait..."
  cd $1; venv/bin/python3 benchmark.py
}

#Спросить тип установки
#проверить индексы, если плохо то удалить
#распаковать индексы
#Согласно типу установки сконфигурить бенчмарк
#запустить бенчмарк


echo "Install script"

echo -ne "Select type:\n 1 - Normal pack\n 2 - Small pack (default)\n> "

read item
case "$item" in
    1) echo "Running normal tests..."
        TestAndUnpackIndex benchmark_index_single_bucket_single_parquet_file.tar.gz benchmark_index_single_bucket_single_parquet_file $INDEXDIR
        TestAndUnpackIndex benchmark_index_many_bucket_many_parquet_file_normal.tar.gz benchmark_index_many_bucket_many_parquet_file $INDEXDIR
        InstallBenchmark $BASEDIR
        ConfigureNormalBenchmark
        ExecuteBenchmark $BASEDIR/$BENCHDIR
        ;;
    *) echo "Running small tests..."
        TestAndUnpackIndex benchmark_index_single_bucket_single_parquet_file.tar.gz benchmark_index_single_bucket_single_parquet_file $INDEXDIR
        TestAndUnpackIndex benchmark_index_many_bucket_many_parquet_file_small.tar.gz benchmark_index_many_bucket_many_parquet_file $INDEXDIR
        InstallBenchmark $BASEDIR
        ConfigureSmallBenchmark
        ExecuteBenchmark $BASEDIR/$BENCHDIR
        exit 0
        ;;
#    *) echo "Ничего не ввели. Выполняем действие по умолчанию..."
#        ;;
esac

exit

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

