#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# проверить подключение к ресту
# проверить ролевую модель доступа к индексам
# Если нет - добавить в ролевую модель индексы
# Запустить одиночный прогон
# *Если указано, то запустить нагрузочный тест

import os
import sys
import re
import argparse
import configparser
import time


# import json

def load_cfg(config_filename):
    config = configparser.ConfigParser(allow_no_value=True)
    if os.path.exists(config_filename) and os.path.isfile(config_filename):
        config.read(config_filename)
    else:
        print("Configuration file not found.", file=sys.stderr)
        quit(255)
    return config


def main():
    parser = argparse.ArgumentParser(add_help=True,
                                     allow_abbrev=False,
                                     # formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                     description='Benchmark test utility')
    parser.add_argument('--connector', default='rest', choices=['rest', 'splunk', 'zeppelin', 'db_dispatcher'],
                        help='Set connector type')
    parser.add_argument('--config', default='benchmark.cfg', help='Configuration file')
    args = parser.parse_args()

    config_filename = args.config
    if config_filename == 'benchmark.cfg':
        config_filename = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'benchmark.cfg')

    cfg = load_cfg(config_filename)

    conn = None
    if args.connector == 'rest':
        from libbenchmark.connector_rest import ConnectorRest
        conn = ConnectorRest(**cfg._sections[args.connector])
    elif args.connector == 'splunk':
        from libbenchmark.connector_splunk import ConnectorSplunk
        conn = ConnectorSplunk(**cfg._sections[args.connector])
        pass
    elif args.connector == 'zeppelin':
        from libbenchmark.connector_zeppelin import ConnectorZeppelin
        conn = ConnectorZeppelin(**cfg._sections[args.connector])
        pass
    elif args.connector == 'db_dispatcher':
        from libbenchmark.connector_db_dispatcher import ConnectorDBDispatcher
        conn = ConnectorDBDispatcher(**cfg._sections[args.connector])
        pass
    else:
        parser.print_help()
        quit(255)

    query_list = list(map(lambda x: dict(cfg._sections[x]),
                          filter(lambda x: re.match("^query_\d$", x), dict(cfg._sections).keys())))
    conn.connect()

    for query in query_list:
        if "query" not in query:
            continue
        if "estimated_time" not in query:
            query["estimated_time"] = 0
        if "timeout" not in query:
            query["timeout"] = 300

        # print(query)
        conn.request(query['query'])
        while True:
            status = conn.get_status()
            time.sleep(0.2)
            query['time'] = conn.query_time()
            if conn.is_done():
                query['status'] = "ok"
                break
            if conn.is_error():
                query['status'] = "error"
                break
            if (time.time() - conn.time_query) > int(query['timeout']):
                query['status'] = "timeout"
                break

    for query in query_list:
        print("\nStatus={status}, Time execution {time}, estimated time {estimated_time}, query = {query}".format(**query))


if __name__ == '__main__':
    main()
