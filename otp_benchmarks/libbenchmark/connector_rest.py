#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import requests
import random
import time


class ConnectorRest:
    def __init__(self, **kwargs):
        self.baseurl = kwargs['baseurl']
        self.login = kwargs['login']
        self.password = kwargs['password']
        logformat = '%(asctime)-15s %(levelname)-10s pid=%(process)d %(module)s:%(lineno)d func=%(funcName)s - %(message)s'
        logging.basicConfig(
            format=logformat,
            level=logging.getLevelName(kwargs['loglevel'])
        )
        self.log = logging.getLogger(__name__)
        self.requests = requests.Session()
        self.last_response = None
        self.query = 0
        self.sid = 0
        self.tws = 0
        self.twf = 0
        self.cache_ttl = 0
        self.time_query = 0
        self.time_finish = 0

        self.timeout_create_job = 5  # in seconds
        self.timeout_cache_job = 5  # in seconds

    def connect(self):
        # def login(base_url, api_login, api_password):
        self.log.debug("Connect, and get token...")
        data_get = {
            "username": self.login,
            "password": self.password
        }
        r = self.requests.post(self.baseurl + "/api/auth/login", json=data_get)
        if r.ok:
            # self.cookies = r.cookies
            return 1
        else:
            print("HTTP %i - %s, Message %s" % (r.status_code, r.reason, r.text))
            return

    def request(self, query, tws=0, twf=0, cache_ttl=30, preview=False, field_extraction=False):
        self.sid = int(random.randint(1, 10000))
        self.query = query
        self.cache_ttl = cache_ttl
        self.tws = tws
        self.twf = twf
        self.requests.post(self.baseurl + "/api/makejob",
                           data={
                               "sid": self.sid,
                               "original_spl": str(self.query),
                               "tws": self.tws,
                               "twf": self.twf,
                               "username": self.login,
                               "preview": preview,
                               "field_extraction": field_extraction,
                               "cache_ttl": self.cache_ttl,
                           })
        self.time_query = time.time()
        self.time_finish = 0
        self.last_response = None

    def is_error(self):
        if not self.last_response:
            self.get_status()
        if self.last_response['total_status'] == "error":
            return True
        return False

    def is_done(self):
        if not self.last_response:
            self.get_status()
        if self.last_response['total_status'] == "finished":
            return True
        return False

    def query_time(self):
        if self.time_finish < self.time_query:
            return -1
        return self.time_finish - self.time_query

    def get_status(self):
        if self.last_response and self.last_response['total_status'] == 'error':
            return self.last_response

        response = self.requests.get(
            self.baseurl + "/api/checkjob",
            params={
                "original_spl": str(self.query),
                "tws": self.tws,
                "twf": self.twf,
                "cache_ttl": self.cache_ttl
            }
        ).json()

        if response["status"] == "success":
            response['total_status'] = 'finished'
            if self.time_finish < self.time_query:
                self.time_finish = time.time()

        elif response["status"] in ["running", "new"]:
            response['total_status'] = 'in_progress'

        elif response["status"] in ["notfound", "rest_error"]:
            if (self.time_query - time.time()) > self.timeout_create_job:
                self.log.error(r"Dispatcher failed to create Job. %s" % response["status"])
                response['total_status'] = 'error'
            else:
                response['total_status'] = 'in_progress'

        elif response["status"] == "failed":
            response['total_status'] = 'error'
            self.log.error("Dispatcher failed Job. %s" % response["error"])

        elif response["status"] == "nocache":
            if (self.time_query - time.time()) > self.timeout_cache_job:
                self.log.error("Cache was expired or removed.")
                response['total_status'] = 'error'
            else:
                response['total_status'] = 'in_progress'

        elif response["status"] == "canceled":
            response['total_status'] = 'error'
            self.log.error("Job was canceled because of %s." % response["error"])

        else:
            response['total_status'] = 'error'
            self.log.error("Dispatcher failed. Unknown Exception.")

        self.last_response = response
        return response

    def result(self):
        pass


if __name__ == '__main__':
    print("This is module...")

"""
import os
import requests
import time
import random
from functools import lru_cache
import pandas as pd

api_login = os.environ.get("OT_REST_LOGIN")
api_password = os.environ.get("OT_REST_PASSWORD")
base_url = os.environ.get("OT_REST_IP")

def read_search(path):
    search = ""
    with open(path, "r") as file:
        search = file.read()
    return search

@lru_cache()
def login(base_url, api_login, api_password):
    print("Getting token...")
    data_get = {"username": api_login, "password": api_password}
    r = requests.post(base_url + "api/auth/login", json=data_get)
    if r.ok:
        authToken = r.headers["Set-Cookie"]
        cookies = r.cookies
        return authToken, cookies
    else:
        print("HTTP %i - %s, Message %s" % (r.status_code, r.reason, r.text))


def get_data(
    search,
    tws="0",
    twf="0",
    username="admin",
    preview="false",
    field_extraction="false",
    cache_ttl="300",
    timeout="300",
):
    authToken, cookies = login(base_url, api_login, api_password)
    requests.post(
        base_url + "api/makejob",
        data={
            "sid": str(random.randint(0, 10000)),
            "original_spl": str(search),
            "tws": tws,
            "twf": twf,
            "username": username,
            "preview": preview,
            "field_extraction": field_extraction,
            "cache_ttl": cache_ttl,
        },
        cookies=cookies,
    )
    tries_count = 0
    while True:
        response = requests.get(
            base_url + "api/checkjob",
            params={
                "original_spl": str(search),
                "tws": "0",
                "twf": "0",
                "cache_ttl": "300",
            },
            cookies=cookies,
        ).json()
        if response["status"] == "success":
            cid = response["cid"]
            response_get_data = requests.get(
                base_url + "api/getresult", params={"cid": cid}
            ).json()

            def get_data_from_url(url):
                return requests.get(base_url + url).content

            urls = response_get_data["data_urls"]
            urls_json = list(filter(lambda x: "json" in x, urls))
            response_data_list =list( map(get_data_from_url, urls_json))
            response_data = b''.join(response_data_list)
            df = pd.read_json(response_data, lines=True)
            return df

        elif response["status"] in ["running", "new"]:
            time.sleep(1)
        elif response["status"] in ["notfound", "rest_error"]:
            print(f"RESPONSE {response}")
            tries_count += 1
            if tries_count > 3:
                print(r"Dispatcher failed to create Job.")
                print(response["status"])
                break
            else:
                time.sleep(3)
        elif response["status"] == "failed":
            print(response["error"])
            print("Dispatcher failed Job.")
            break
        elif response["status"] == "nocache":
            tries_count += 1
            if tries_count > 3:
                 print("Cache was expired or removed.")
                 break
            else:
                time.sleep(3)
        elif response["status"] == "canceled":
            print("Job was canceled because of %s." % response["error"])
            break
        else:
            print("Dispatcher failed. Unknown Exception.")
            break
"""
