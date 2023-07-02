#!/bin/bash
#set -x
KB=$((1024))
MB=$(($KB*1024))
GB=$(($MB*1024))
# APP_PREFIX=sudo
APP_PREFIX="numactl --cpunodebind=0 --membind=0"

db_path=$(pwd)
db_bench=$db_path
db_include=$db_path/include
ycsb_path=$db_path/ycsbc

sata_path=/tmp/pm_test
ssd_path=/media/nvme1/pm_test
pm_path=/mnt/pmem0.1/pm_test
# leveldb_path=/tmp/leveldb-wzh
leveldb_path=$pm_path
output_path=$db_path/output
output_file=$output_path/result.out

export CPLUS_INCLUDE_PATH=$db_path/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=$db_path:$LIBRARY_PATH
export LD_LIBRARY_PATH=$db_path:$LD_LIBRARY_PATH 

benchmarks="overwrite,readrandom,readseq"
# benchmarks2="fillseqNofresh,readrandom,readseq"
ycsb_input=1KB_ALL

num_thread=1
value_size=1024
num_kvs=$((10*$MB))
write_buffer_size=$((64*$MB))
max_file_size=$((128*$MB))
key_size=8
pm_size=$((180*$GB))
use_pm=1
flush_ssd=0
throughput=0
bench_readnum="1000000"
bench_compression="none" #"snappy,none"
max_background_jobs="3"
max_bytes_for_level_base=$((8*$GB))
report_write_latency="false"
use_nvm="true"
bloom_bits=16

WRITE80G_FLUSHSSD() {
    leveldb_path=$ssd_path;
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    max_bytes_for_level_base=$((8*$GB))
    flush_ssd=1
}
WRITE80G-1KB-THROUGHPUT() {
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    throughput=1
}
WRITE80G-4KB-THROUGHPUT() {
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    throughput=1
}
WRITE80G-256B() {
    value_size=$((256))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G() {
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-4K() {
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-16K() {
    value_size=$((16*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-64K() {
    value_size=$((64*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G_8GNVM() {
    leveldb_path=$ssd_path;
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    max_bytes_for_level_base=$((8*$GB))
    flush_ssd=1
}
WRITE80G_16GNVM() {
    leveldb_path=$ssd_path;
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    max_bytes_for_level_base=$((16*$GB))
    flush_ssd=1
}
WRITE80G_32GNVM() {
    leveldb_path=$ssd_path;
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    max_bytes_for_level_base=$((32*$GB))
    flush_ssd=1
}
WRITE80G_64GNVM() {
    leveldb_path=$ssd_path;
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    max_bytes_for_level_base=$((64*$GB))
    flush_ssd=1
}

RUN_DB_BENCH() {
    CLEAN_DB
    if [ -f "$output_file" ]; then
        rm $output_file
        echo "delete output_file: $output_file"
    fi
    parameters="--benchmarks=$benchmarks \
                --db=$leveldb_path \
                --wal_dir=$leveldb_path \
                --num=$num_kvs \
                --reads=$num_kvs \
                --value_size=$value_size \
                --reads=$bench_readnum \
                --compression_type=$bench_compression \
                --max_background_jobs=$max_background_jobs \
                --max_bytes_for_level_base=$max_bytes_for_level_base \
                --report_write_latency=$report_write_latency \
                --use_nvm_module=$use_nvm \
                --pmem_path=$pm_path \
                --throughput=$throughput \
                -bloom_bits=$bloom_bits \
                -key_size=$key_size
                "
    cmd="$APP_PREFIX $db_bench/db_bench $parameters >> $output_file"
    echo $cmd >> $output_file
    echo $cmd
    eval $cmd
}

RUN_YCSB(){
    CLEAN_DB
    if [ -f "$output_file" ]; then
        rm $output_file
        echo "delete output_file: $output_file"
    fi
    cmd="$APP_PREFIX $ycsb_path/ycsbc $ycsb_path/input/$ycsb_input >> $output_file"
    echo $cmd >> $output_file
    echo $cmd
    eval $cmd
}

CLEAN_DB() {
  if [ -z "$pm_path" ]
  then
        echo "PM path empty."
        exit
  fi
  if [ -z "$leveldb_path" ]
  then
        echo "DB path empty."
        exit
  fi
  rm -rf ${leveldb_path:?}/*
  rm -rf ${pm_path:?}/*
#   mkdir -p $pm_path
}

SET_OUTPUT_PATH() {
    if [ ! -d "$output_path" ]; then
        # 如果目录不存在，则创建目录
        mkdir $output_path
        echo "Created output_path: $output_path"
    fi
    # else
    #     # 如果目录已存在，则清空目录下的所有文件
    #     rm -rf "${output_path:?}/"*
    #     echo "Cleared output_path: $output_path"
    # fi
    # touch $output_file
    # echo "Created file: $output_file"
}

MAKE() {
  if [ ! -d "$db_bench" ]; then
    # 如果目录不存在，则创建目录
    mkdir "$db_bench"
  fi
  cd $db_bench
#   make clean
  make -j64

  cd $ycsb_path
  #make clean
  make
  cd ..
}

DB_BENCH_TEST() {
    echo "------------db_bench------------"
    benchmarks="fillrandom,stats,readrandom,stats"
    # echo "------256B random write/read-----"
    # output_file=$output_path/Rnd_NVM_256B
    # WRITE80G-256B
    # RUN_DB_BENCH

    echo "------1KB random write/read-----"
    output_file=$output_path/Rnd_NVM_1K
    WRITE80G
    RUN_DB_BENCH

    echo "------4KB random write/read-----"
    output_file=$output_path/Rnd_NVM_4K
    WRITE80G-4K
    RUN_DB_BENCH

    echo "------16KB random write/read-----"
    output_file=$output_path/Rnd_NVM_16K
    WRITE80G-16K
    RUN_DB_BENCH

    echo "------64KB random write/read-----"
    output_file=$output_path/Rnd_NVM_64K
    WRITE80G-64K
    RUN_DB_BENCH


    benchmarks="fillseq,stats,readseq,stats"
    # echo "------256B random write/read-----"
    # output_file=$output_path/Seq_NVM_256B
    # WRITE80G-256B
    # RUN_DB_BENCH

    echo "------1KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_1K
    WRITE80G
    RUN_DB_BENCH

    echo "------4KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_4K
    WRITE80G-4K
    RUN_DB_BENCH

    echo "------16KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_16K
    WRITE80G-16K
    RUN_DB_BENCH

    echo "------64KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_64K
    WRITE80G-64K
    RUN_DB_BENCH

    CLEAN_DB
}

DB_BENCH_THROUGHPUT() {
    echo "------------db_bench------------"
    benchmarks="fillrandom,stats"

    echo "------1K random write/read-----"
    output_file=$output_path/Throughput_Rnd_NVM_1KB
    WRITE80G-1KB-THROUGHPUT
    RUN_DB_BENCH

    echo "------4K random write/read-----"
    output_file=$output_path/Throughput_Rnd_NVM_4KB
    WRITE80G-4KB-THROUGHPUT
    RUN_DB_BENCH
    throughput=0

    CLEAN_DB
}

DB_BENCH_TEST_FLUSHSSD() {
    echo "----------db_bench_flushssd----------"
    benchmarks="fillrandom,stats,readrandom,stats"
    echo "---8GNVM--4KB random write/read---"
    output_file=$output_path/NVM8G_Rnd_4K
    WRITE80G_8GNVM
    RUN_DB_BENCH

    echo "---16GNVM--4KB random write/read---"
    output_file=$output_path/NVM16G_Rnd_4K
    WRITE80G_16GNVM
    RUN_DB_BENCH

    echo "---32GNVM--4KB random write/read---"
    output_file=$output_path/NVM32G_Rnd_4K
    WRITE80G_32GNVM
    RUN_DB_BENCH

    echo "---64GNVM--4KB random write/read---"
    output_file=$output_path/NVM64G_Rnd_4K
    WRITE80G_64GNVM
    RUN_DB_BENCH

    flush_ssd=0
    leveldb_path=$pm_path;
    CLEAN_DB
}

YCSB_TEST(){
    cd $ycsb_path
    echo "------------YCSB------------"
    echo "-----1KB YCSB performance-----"
    output_file=$output_path/YCSB_1KB
    ycsb_input=1KB_ALL
    RUN_YCSB

    echo "-----4KB YCSB performance-----"
    output_file=$output_path/YCSB_4KB
    ycsb_input=4KB_ALL
    RUN_YCSB
    cd ..
}

YCSB_TEST_LATENCY(){
    cd $ycsb_path
    echo "------------YCSB------------"
    echo "-----1KB YCSB latency-----"
    output_file=$output_path/YCSB_1KB_Latency
    ycsb_input=1KB_ALL_Latency
    RUN_YCSB

    echo "-----4KB YCSB latency-----"
    output_file=$output_path/YCSB_4KB_Latency
    ycsb_input=4KB_ALL_Latency
    RUN_YCSB
    cd ..
}

YCSB_TEST_SSD(){
    cd $ycsb_path
    echo "------------YCSB------------"
    echo "-----1KB YCSB SSD-----"
    output_file=$output_path/YCSB_1KB_SSD
    ycsb_input=1KB_ALL_SSD
    RUN_YCSB

    echo "-----4KB YCSB SSD-----"
    output_file=$output_path/YCSB_4KB_SSD
    ycsb_input=4KB_ALL_SSD
    RUN_YCSB
    cd ..
}

MAKE
SET_OUTPUT_PATH

echo "如果程序出问题请make clean"

echo "chapter 4.1"
# DB_BENCH_TEST
# DB_BENCH_THROUGHPUT

echo "chapter 4.2"
# YCSB_TEST
# YCSB_TEST_LATENCY

echo "chapter 4.3"
DB_BENCH_TEST_FLUSHSSD
# YCSB_TEST_SSD

CLEAN_DB
# sudo cp build/libleveldb.a /usr/local/lib/
# sudo cp -r include/leveldb /usr/local/include/
# -exec break __sanitizer::Die
