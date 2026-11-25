# -*- coding: utf-8 -*-
import logging
from datetime import datetime, timedelta, timezone
import requests
from odoo import api, models

_logger = logging.getLogger(__name__)
UBPORTS_PUSH_URL = 'https://push.ubports.com/notify'
DEFAULT_APP_ID = 'ubtms_ubtms'


class MailActivity(models.Model):
    _inherit = 'mail.activity'

    @api.model_create_multi
    def create(self, vals_list):
        activities = super().create(vals_list)
        for activity in activities:
            self._send_activity_push(activity)
        return activities

    def write(self, vals):
        res = super().write(vals)
        if 'user_id' in vals:
            for activity in self:
                self._send_activity_push(activity)
        return res

    def _send_activity_push(self, activity):
        user = activity.user_id
        actor_ids = set()
        env = getattr(self, 'env', None)
        if env and getattr(env, 'uid', None):
            actor_ids.add(env.uid)
        create_uid_obj = getattr(activity, 'create_uid', False)
        creator_id = create_uid_obj.id if create_uid_obj and getattr(create_uid_obj, 'id', None) else False
        if creator_id:
            actor_ids.add(creator_id)

        if not user or getattr(user, 'id', None) in actor_ids:
            return
        token = getattr(user, 'ubports_push_token', False)
        if not token:
            return

        summary = activity.summary or (activity.activity_type_id.name if activity.activity_type_id else '') or 'New Activity'
        deadline = str(activity.date_deadline or 'Today')
        res_name = activity.res_name or ''
        deep_link = f"ubtms://notification?type=Activity&id={activity.id}&odoo_id=1"
        expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%SZ')

        record = {
            'model': 'mail.activity',
            'record_id': activity.id,
            'name': summary,
            'summary': summary,
            'deadline': deadline,
            'res_name': res_name,
            'res_model': getattr(activity, 'res_model', '') or '',
            'res_id': getattr(activity, 'res_id', 0) or 0,
            'user_id': user.id if user else False,
            'create_uid': creator_id,
        }

        card = {
            'summary': f"Activity: {summary}",
            'body': f"Due: {deadline} - {res_name}",
            'icon': 'assets/logo.png',
            'popup': True,
            'persist': True,
            'actions': [deep_link, "appid://ubtms/ubtms/current-user-version"],
            'sound': 'sounds/lomiri/notifications/Positive.ogg',
            'vibrate': {
                'pattern': [200, 100, 200],
                'repeat': 1,
            },
            'record': record,
        }

        payload = {
            'appid': DEFAULT_APP_ID,
            'token': token,
            'expire_on': expire_on,
            'data': {
                'notification': {
                    'card': card,
                    'sound': 'sounds/lomiri/notifications/Positive.ogg',
                    'vibrate': {
                        'pattern': [200, 100, 200],
                        'repeat': 1,
                    },
                    'emblem-counter': {
                        'count': 1,
                        'visible': True,
                    },
                },
                'record': record,
            },
        }

        try:
            requests.post(UBPORTS_PUSH_URL, json=payload, headers={'Content-Type': 'application/json'}, timeout=5)
        except Exception as e:
            _logger.warning("Failed sending UBports push for activity %s: %s", activity.id, e)
