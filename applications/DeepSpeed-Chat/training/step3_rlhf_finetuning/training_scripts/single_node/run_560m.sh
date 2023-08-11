#!/bin/bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: Apache-2.0
scl enable devtoolset-9 bash
export LD_LIBRARY_PATH=/home/huangzhiguo/anaconda3/envs/deepspeed/lib:$LD_LIBRARY_PATH

# DeepSpeed Team
ACTOR_MODEL_PATH=./output/output_step1/
CRITIC_MODEL_PATH=./output/output_step2/
ACTOR_ZERO_STAGE=2
CRITIC_ZERO_STAGE=2
OUTPUT=$5

echo $1,$2,$3,$4,$5
if [ "$OUTPUT" == "" ]; then
    OUTPUT=./output/output_step3
fi
if [ "$ACTOR_ZERO_STAGE" == "" ]; then
    ACTOR_ZERO_STAGE=2
fi
if [ "$CRITIC_ZERO_STAGE" == "" ]; then
    CRITIC_ZERO_STAGE=2
fi
mkdir -p $OUTPUT

Num_Padding_at_Beginning=1 # this is model related

Actor_Lr=9.65e-6
Critic_Lr=5e-6

if [[ $0 =~ ^\/.* ]]; then
    script=$0
    echo '0:'$script
else
    script=$(pwd)/$0
    echo 'pwd:'$script
fi
path_dir=${script%%training_scripts*}
#!bug1 RuntimeError: Subtraction, the `-` operator -> ds_attention.py,1-input_mask修改为~input_mask
ds --master_port 12346 --num_gpu 2 $path_dir'main.py' \
   --data_path $HOME/.cache/huggingface/hub/datasets--Dahoas--full-hh-rlhf \
   --data_split 2,4,4 \
   --actor_model_name_or_path $ACTOR_MODEL_PATH \
   --critic_model_name_or_path $CRITIC_MODEL_PATH \
   --tokenizer_name_or_path bigscience/tokenizer \
   --num_padding_at_beginning 1 \
   --per_device_train_batch_size 2 \
   --per_device_mini_train_batch_size 2 \
   --generation_batch_numbers 1 \
   --ppo_epochs 1 \
   --max_answer_seq_len 256 \
   --max_prompt_seq_len 256 \
   --actor_learning_rate ${Actor_Lr} \
   --critic_learning_rate ${Critic_Lr} \
   --num_train_epochs 1 \
   --lr_scheduler_type cosine \
   --gradient_accumulation_steps 1 \
   --disable_actor_dropout \
   --num_warmup_steps 100 \
   --deepspeed --seed 1234 \
   --enable_hybrid_engine \
   --actor_zero_stage $ACTOR_ZERO_STAGE \
   --critic_zero_stage $CRITIC_ZERO_STAGE \
   --enable_ema \
   --output_dir $OUTPUT \
   --print_answers \
   --enable_tensorboard \
   --tensorboard_path $OUTPUT \
    > $OUTPUT/step3_training_bloom_560m_full_hh_rlhf.log 2>&1 &