# -*- coding: utf-8 -*-
import logging
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
        for user in assigned_users:
            token = getattr(user, 'ubports_push_token', False)
            if not token:
                continue

            project_name = task.project_id.name if task.project_id else ''
            deep_link = f"ubtms://notification?type=Task&id={task.id}&odoo_id=1"
            payload = {
                'appid': DEFAULT_APP_ID,
                'token': token,
                'data': {
                    'notification': {
                        'card': {
                            'summary': f"Task Assigned: {task.name}",
                            'body': f"Project: {project_name}" if project_name else "New task assigned",
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
                _logger.warning("Failed sending UBports push for task %s: %s", task.id, e)
