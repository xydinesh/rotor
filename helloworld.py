from __future__ import print_function


def handler(event, context):
    return {"message": "Hello, World!"}


def post_handler(event, context):
    return {"message": "I should have created something..."}
