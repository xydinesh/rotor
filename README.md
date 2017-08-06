# rotor
Group texting application using AWS api gateway, lambda, dynamodb and twilio API. Deployment via terraform.

## Development workflow

```
zip -r9 rotor.zip rotor.py
terraform apply
```

## Cleanup

```
terraform destroy
```

## Reference

I used this repository as reference to apigateway configurations, [AWSinAction](https://github.com/xydinesh/apigateway)
