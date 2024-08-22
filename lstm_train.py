#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import glob
import pandas as pd
import pickle
from datetime import datetime
from loguru import logger
from dotenv import dotenv_values
import time

import tensorflow as tf
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense, Conv2D, MaxPooling2D, Flatten, TimeDistributed, Conv1D, MaxPooling1D
from tensorflow.python.ops.numpy_ops import np_config

np_config.enable_numpy_behavior()

# import numpy as np
# from sklearn.model_selection import train_test_split
# from sklearn.preprocessing import MinMaxScaler
# from tensorflow.keras.callbacks import EarlyStopping
# from keras.models import Sequential
# from keras.layers import LSTM, Dense
# from keras.preprocessing.sequence import TimeseriesGenerator
# import gc
# gc.collect()

logger_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'logs', os.path.basename(__file__) + ".log"))
logger.add(logger_path, rotation="500MB", encoding="utf-8", enqueue=True, retention="1 day", catch=True)

config = dotenv_values(".env")

enable_cnn = int(config["ENABLE_CNN"])
use_pct = int(config["USE_PCT"])
time_steps = int(config["TIME_STEPS"])
lstm_units = int(config["LSTM_UNITS"])
n_features = int(config["N_FEATURES"])
epochs = int(config["EPOCHS"]) + 1
model_batch = int(config["MODEL_BATCH"])
model_weight = float(config["MODEL_WEIGHT"])
model_learning_rate = float(config["MODEL_LEARNING_RATE"])


def parse_tfrecord32(example_proto):
    feature_description = {
        'X': tf.io.FixedLenFeature([], tf.string),
        'y': tf.io.FixedLenFeature([], tf.float32),
    }
    example = tf.io.parse_single_example(example_proto, feature_description)
    X = tf.io.parse_tensor(example['X'], out_type=tf.float32)
    y = example['y']
    return X, y


def get_dataset():
    num_parallel_calls = tf.data.experimental.AUTOTUNE

    if enable_cnn:
        train_path = os.path.join('ml_data', 'short_tfrecord_cnn', '*_train')
        test_path = os.path.join('ml_data', 'short_tfrecord_cnn', '*_test')
    elif use_pct == 1:
        train_path = os.path.join('ml_data', 'short_tfrecord_pct', '*_train')
        test_path = os.path.join('ml_data', 'short_tfrecord_pct', '*_test')
    else:
        train_path = os.path.join('ml_data', 'short_tfrecord', '*_train')
        test_path = os.path.join('ml_data', 'short_tfrecord', '*_test')

    train_files = glob.glob(train_path)
    train_files = [f for f in train_files if os.path.getsize(f) > 20]
    test_files = glob.glob(test_path)
    test_files = [f for f in test_files if os.path.getsize(f) > 20]
    train_dataset = tf.data.TFRecordDataset(train_files, compression_type='GZIP').map(parse_tfrecord32,
                                                                                      num_parallel_calls=num_parallel_calls)
    test_dataset = tf.data.TFRecordDataset(test_files, compression_type='GZIP').map(parse_tfrecord32,
                                                                                    num_parallel_calls=num_parallel_calls)
    return train_dataset, test_dataset


def get_vanilla_lstm_model(optimizer, time_steps, n_features):
    model = Sequential()
    model.add(LSTM(lstm_units, activation='tanh', input_shape=(time_steps, n_features)))
    model.add(Dense(1, activation='sigmoid'))
    model.compile(optimizer=optimizer, loss="binary_crossentropy", metrics=['accuracy'])

    return "vanilla", model


# def get_stacked_lstm_model(optimizer, time_steps, n_features):
#     model = Sequential()
#     model.add(LSTM(lstm_units, activation='relu', return_sequences=True, input_shape=(time_steps, n_features)))
#     model.add(LSTM(lstm_units, activation='tanh'))
#     model.add(Dense(1, activation='sigmoid'))
#     model.compile(optimizer=optimizer, loss="binary_crossentropy", metrics=['accuracy'])

#     return "stacked", model


def get_stacked_lstm_model(optimizer, time_steps, n_features):
    model = Sequential()
    model.add(LSTM(lstm_units, activation='tanh', return_sequences=True, input_shape=(time_steps, n_features)))
    model.add(LSTM(lstm_units, activation='tanh'))
    model.add(Dense(1, activation='sigmoid'))
    # model.compile(optimizer=optimizer, loss="binary_crossentropy", metrics=['accuracy'])
    model.compile(optimizer=optimizer, loss="mse", metrics=['accuracy'])

    return "stacked", model


def get_cnn_lstm_model(optimizer, time_steps, n_features):
    model = Sequential()
    model.add(TimeDistributed(Conv1D(filters=64, kernel_size=3, activation='relu'),
                              input_shape=(None, time_steps, n_features)))
    model.add(TimeDistributed(MaxPooling1D(pool_size=2)))
    model.add(TimeDistributed(Flatten()))

    model.add(LSTM(lstm_units, activation='tanh'))
    model.add(Dense(1, activation='sigmoid'))
    model.compile(optimizer=optimizer, loss="binary_crossentropy", metrics=['accuracy'])

    return "cnn", model


def main():
    logger.info(f"GPU Available: {tf.config.list_physical_devices('GPU')}")
    logger.info(f"GPU Device Name: {tf.test.gpu_device_name()}")

    # 创建一个简单的 LSTM 模型
    # optimizer = tf.keras.optimizers.Adam(clipvalue=0.5, learning_rate=model_learning_rate)
    # optimizer = tf.keras.optimizers.Adam()

    if enable_cnn == 1:
        model_name, model = get_cnn_lstm_model("adam", time_steps, n_features)
    else:
        # model_name, model = get_vanilla_lstm_model("adam", time_steps, n_features)
        model_name, model = get_stacked_lstm_model("adam", time_steps, n_features)

    for i in range(1, epochs):
        start_time = time.time()  # 记录开始时间

        train_dataset, test_dataset = get_dataset()

        history = model.fit(train_dataset.batch(model_batch),
                            epochs=epochs,
                            validation_data=test_dataset.batch(model_batch),
                            class_weight={0: 1., 1: model_weight})

        now = datetime.now()
        now_str = now.strftime('%Y-%m-%d_%H-%M')

        # history_path = os.path.join('J:', os.sep, 'ml_model', f"history-{now_str}-1-lstm-200-layers-epoch{i}.pkl")
        # model_path = os.path.join('J:', os.sep, 'ml_model', f"lstm-{now_str}-1-lstm-200-layers-epoch{i}.h5")

        history_path = os.path.join('ml_model',
                                    f"history-{now_str}-{model_name}-lstm-{lstm_units}-units-{i}-epochs.pkl")
        model_path = os.path.join('ml_model', f"lstm-{now_str}-{model_name}-lstm-{lstm_units}-units-{i}-epochs.h5")

        with open(history_path, 'wb') as f:
            pickle.dump(history.history, f)

        logger.info(history)

        # with open('history-2023-06-08.pkl', 'rb') as f:
        #    history = pickle.load(f)

        model.save(model_path)
        # model = load_model('lstm-2023-06-08.h5')

        end_time = time.time()  # 记录结束时间
        execution_time = end_time - start_time
        logger.info(f"Execution time: {execution_time}")


main()
