from __future__ import print_function
import json


def func_not_found():
    return {"message": "Function not found"}


def handler(event, context):
    func = event.get("func", None)
    parameters = event.get("parameters", None)
    rotor = Rotor()
    if parameters is None:
        return getattr(rotor, func, func_not_found)()
    else:
        return getattr(rotor, func, func_not_found)(parameters)


class Rotor(object):

    def get_handler(self):
        return {"message": "hello world !"}

    def post_handler(self):
        return {"message": "I should have created something..."}

    def vpath_handler(self, event):
        return {
            "message": "I vpath method event:{0} ".format(event.get('rotor_id'))
        }

    def get_rotor_name(self, event):
        return {
            "message": "Return name of {0}".format(event.get('rotor_id'))
        }
