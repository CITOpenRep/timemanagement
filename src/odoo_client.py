# -*- coding: utf-8 -*-
# MIT License
#
# Copyright (c) 2025 CIT-Services
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import xmlrpc.client
import logging


class OdooClient:
    """
    A client to interact with the Odoo XML-RPC API.
    """

    def __init__(self, url, db, username, password):
        """
        Initialize the Odoo client.

        Args:
            url (str): The base URL of the Odoo instance (e.g. https://my.odoo.com).
            db (str): The Odoo database name.
            username (str): The username (usually email).
            password (str): The user’s password or API key.
        """
        self.url = url
        self.db = db
        self.username = username
        self.password = password
        self.uid = self._login()
        self.models = self._get_model_proxy()

    def search(self, model, domain):
            return self.models.execute_kw(
                self.db, self.uid, self.password,
                model, 'search', [domain]
            )

    def read(self, model, ids, fields=None):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'read', [ids], {"fields": fields or []}
        )

    def _login(self):
        """
        Authenticate and return the user ID.

        Returns:
            int: UID if authentication is successful, otherwise raises an exception.
        """
        try:
            common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
            uid = common.authenticate(self.db, self.username, self.password, {})
            if not uid:
                raise ValueError(
                    f"Authentication failed for user '{self.username}' on database '{self.db}'"
                )
            return uid
        except Exception as e:
            raise ConnectionError(f"Login failed: {e}")

    def _get_model_proxy(self):
        """
        Get a model proxy to call object methods.

        Returns:
            ServerProxy: A proxy for calling model methods.
        """
        try:
            return xmlrpc.client.ServerProxy(
                f"{self.url}/xmlrpc/2/object", allow_none=True
            )
        except Exception as e:
            raise ConnectionError(f"Failed to create model proxy: {e}")

    def call(self, model, method, args=None, kwargs=None):
        """
        Call a method on a given model.

        Args:
            model (str): The Odoo model name (e.g. 'res.partner').
            method (str): The method name to call (e.g. 'search_read').
            args (list): Positional arguments for the method.
            kwargs (dict): Keyword arguments for the method.

        Returns:
            Any: The result of the method call.
        """
        args = args or []
        kwargs = kwargs or {}
        try:
            return self.models.execute_kw(
                self.db, self.uid, self.password, model, method, args, kwargs
            )
        except Exception as e:
            raise RuntimeError(f"Failed calling '{method}' on '{model}': {e}")
