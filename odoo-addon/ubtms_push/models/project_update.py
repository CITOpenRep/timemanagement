# -*- coding: utf-8 -*-
import logging
from datetime import datetime, timedelta, timezone
import requests
from odoo import api, models

_logger = logging.getLogger(__name__)
UBPORTS_PUSH_URL = 'https://push.ubports.com/notify'
DEFAULT_APP_ID = 'ubtms_ubtms'


class ProjectUpdate(models.Model):
    _inherit = 'project.update'

    @api.model_create_multi
    def create(self, vals_list):
        updates = super().create(vals_list)
        for update in updates:
            self._send_project_update_push(update)
        return updates

    def _get_target_users(self, update):
        project = update.project_id
        if not project:
            return []

        author_ids = set()
        if getattr(update, 'create_uid', False):
            author_ids.add(update.create_uid.id)
        if getattr(update, 'user_id', False):
            author_ids.add(update.user_id.id)
        if getattr(self.env, 'uid', False):
            author_ids.add(self.env.uid)

        target_users = set()

        # Project manager
        manager = getattr(project, 'user_id', None)
        if manager and getattr(manager, 'id', None) and manager.id not in author_ids:
            target_users.add(manager)

        # Project followers
        followers = getattr(project, 'message_partner_ids', None)
        if followers:
            for partner in followers:
                u_ids = getattr(partner, 'user_ids', None)
                if u_ids:
                    for u in u_ids:
                        if getattr(u, 'id', None) and u.id not in author_ids:
                            target_users.add(u)

            try:
                partner_ids = [p.id for p in followers if getattr(p, 'id', None)]
                if partner_ids and hasattr(self.env, '__getitem__'):
                    found_users = self.env['res.users'].search([('partner_id', 'in', partner_ids)])
                    for u in found_users:
                        if getattr(u, 'id', None) and u.id not in author_ids:
                            target_users.add(u)
            except Exception:
                pass

        return [u for u in target_users if getattr(u, 'id', None) not in author_ids]

    def _send_project_update_push(self, update):
        target_users = self._get_target_users(update)
        if not target_users:
            return

        project = update.project_id
        project_name = project.name if project else ''
        update_name = update.name or 'Project Update'
        status_label = getattr(update, 'status', 'on_track') or 'on_track'

        summary = f"Update: {project_name}" if project_name else f"Update: {update_name}"
        body = f"{update_name} ({status_label})"
        deep_link = f"ubtms://notification?type=ProjectUpdate&id={update.id}&odoo_id=1"
        expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%SZ')

        record = {
            'model': 'project.update',
            'record_id': update.id,
            'name': update.name or '',
            'summary': update.name or '',
            'project_status': status_label,
            'status': status_label,
            'progress': getattr(update, 'progress', 0) or 0,
            'description': getattr(update, 'description', '') or '',
            'date': str(getattr(update, 'date', '') or ''),
            'project_id': project.id if project else False,
            'project_name': project_name,
            'user_id': update.user_id.id if getattr(update, 'user_id', False) else False,
            'create_uid': update.create_uid.id if getattr(update, 'create_uid', False) else False,
        }

        card = {
            'summary': summary,
            'body': body,
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

        sent_tokens = set()
        for user in target_users:
            token = getattr(user, 'ubports_push_token', False)
            if not token or token in sent_tokens:
                continue
            sent_tokens.add(token)

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
                _logger.warning("Failed sending UBports push for project update %s to user %s: %s", update.id, user.id, e)
