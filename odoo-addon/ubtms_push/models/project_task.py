# -*- coding: utf-8 -*-
import logging
from datetime import datetime, timedelta, timezone
import requests
from odoo import api, models

_logger = logging.getLogger(__name__)
UBPORTS_PUSH_URL = 'https://push.ubports.com/notify'
DEFAULT_APP_ID = 'ubtms_ubtms'


class ProjectTask(models.Model):
    _inherit = 'project.task'

    @api.model_create_multi
    def create(self, vals_list):
        tasks = super().create(vals_list)
        for task in tasks:
            self._send_task_assignment_push(task)
        return tasks

    def write(self, vals):
        res = super().write(vals)
        if 'user_ids' in vals:
            for task in self:
                self._send_task_assignment_push(task)
        return res

    def _send_task_assignment_push(self, task):
        assigned_users = task.user_ids
        actor_ids = set()
        env = getattr(self, 'env', None)
        if env and getattr(env, 'uid', None):
            actor_ids.add(env.uid)
        create_uid_obj = getattr(task, 'create_uid', False)
        creator_id = create_uid_obj.id if create_uid_obj and getattr(create_uid_obj, 'id', None) else False
        if creator_id:
            actor_ids.add(creator_id)

        for user in assigned_users:
            if getattr(user, 'id', None) in actor_ids:
                continue
            token = getattr(user, 'ubports_push_token', False)
            if not token:
                continue

            project_name = task.project_id.name if task.project_id else ''
            deep_link = f"ubtms://notification?type=Task&id={task.id}&odoo_id=1"
            expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%SZ')

            record = {
                'model': 'project.task',
                'record_id': task.id,
                'name': task.name or '',
                'summary': task.name or '',
                'description': getattr(task, 'description', '') or '',
                'project_id': task.project_id.id if task.project_id else False,
                'project_name': project_name,
                'stage_id': task.stage_id.id if getattr(task, 'stage_id', False) else False,
                'stage_name': task.stage_id.name if getattr(task, 'stage_id', False) else '',
                'deadline': str(getattr(task, 'date_deadline', '') or ''),
                'priority': getattr(task, 'priority', '0') or '0',
                'user_id': user.id if user else False,
                'create_uid': creator_id,
            }

            card = {
                'summary': f"Task Assigned: {task.name}",
                'body': f"Project: {project_name}" if project_name else "New task assigned",
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
                _logger.warning("Failed sending UBports push for task %s: %s", task.id, e)
