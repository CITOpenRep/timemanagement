# -*- coding: utf-8 -*-
import logging
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

    def _send_activity_push(self, activity):
        user = activity.user_id
        token = getattr(user, 'ubports_push_token', False)
        if not token:
            return

        summary = activity.summary or activity.activity_type_id.name or 'New Activity'
        deadline = str(activity.date_deadline or 'Today')
        res_name = activity.res_name or ''
        deep_link = f"ubtms://notification?type=Activity&id={activity.id}&odoo_id=1"

        payload = {
            'appid': DEFAULT_APP_ID,
            'token': token,
            'data': {
                'notification': {
                    'card': {
                        'summary': f"Activity: {summary}",
                        'body': f"Due: {deadline} - {res_name}",
                        'icon': 'assets/logo.png',
                        'popup': True,
                        'persist': True,
                        'actions': [deep_link, f"appid://{DEFAULT_APP_ID}/ubtms/current-user-version"]
                    }
                }
            }
        }

        try:
            requests.post(UBPORTS_PUSH_URL, json=payload, timeout=5)
        except Exception as e:
            _logger.warning("Failed sending UBports push for activity %s: %s", activity.id, e)
