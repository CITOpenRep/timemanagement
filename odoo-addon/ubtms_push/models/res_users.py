# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ResUsers(models.Model):
    _inherit = 'res.users'

    ubports_push_token = fields.Char(string='UBports Push Token', copy=False)

    @api.model
    def register_ubports_token(self, token):
        """Register or update UBports push token for the calling user."""
        if not token:
            return False
        self.env.user.sudo().write({'ubports_push_token': token})
        return True
