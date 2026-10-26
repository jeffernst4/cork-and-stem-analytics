"""Minimal Toast API client"""
import os
import time

import requests
from dotenv import load_dotenv

load_dotenv()

HOST = os.environ["TOAST_HOST"].rstrip("/")


class ToastClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers["Authorization"] = f"Bearer {self._get_token()}"
        self.session.headers["Toast-Restaurant-External-ID"] = os.environ["TOAST_RESTAURANT_GUID"]

    def _get_token(self):
        resp = requests.post(
            f"{HOST}/authentication/v1/authentication/login",
            json={
                "clientId": os.environ["TOAST_CLIENT_ID"],
                "clientSecret": os.environ["TOAST_CLIENT_SECRET"],
                "userAccessType": os.environ.get("TOAST_USER_ACCESS_TYPE", "TOAST_MACHINE_CLIENT"),
            },
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()["token"]["accessToken"]

    def get(self, path, params=None, retries=5):
        """GET a path, waiting and retrying when Toast rate-limits us (HTTP 429)."""
        for attempt in range(retries):
            resp = self.session.get(f"{HOST}{path}", params=params, timeout=60)
            if resp.status_code != 429:
                resp.raise_for_status()
                return resp.json()
            time.sleep(2 ** attempt)
        resp.raise_for_status()

    def get_orders(self, business_date, page_size=100):
        """All orders for one business date (yyyymmdd), following pagination."""
        orders, page = [], 1
        while True:
            batch = self.get(
                "/orders/v2/ordersBulk",
                params={"businessDate": business_date, "pageSize": page_size, "page": page},
            )
            orders.extend(batch)
            if len(batch) < page_size:
                return orders
            page += 1
