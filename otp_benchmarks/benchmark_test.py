#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# проверить подключение к ресту
# проверить ролевую модель доступа к индексам
# Если нет - добавить в ролевую модель индексы
# Запустить одиночный прогон
# *Если указано, то запустить нагрузочный тест

import argparse

def main():
    parser = argparse.ArgumentParser(add_help=True, description='Benchmark test utility')
    parser.set_defaults(role='manage')
    subparsers = parser.add_subparsers(title='Select one of role', dest='role')
    subparsers.add_parser('-c', 'connector', help='Master role', add_help=False)
    subparsers.add_parser('master', help='Master role', add_help=False)


if __name__ == '__main__':
    main()
