# API and Routes Documentation

The API conforms to the [JSON:API](https://jsonapi.org/) specifications with a few additions that have been flagged. The three major deviations from the specifications are:

1. There are non-jsonapi blob `POST upload`/`GET download` routes,
2. The model's `id` are alphanumeric, and
3. The model's use `PATCH/UPDATE` to create/update the models. This is possible because the create/update is idempotent.

These exceptions have been flagged below.

## \*ID Generation

Most API's use server generated auto incrementing integer as id's. In this API, id's are generated client side and are allow to contain any combination of the following characters:
`a-z`, `A-Z`, `0-9`, `-`, and `_`.

The id is otherwise used in the same manner according to the `JSON:API` specifications.

The final caveat is `dhcp-hosts` uses a compound id of its `subnet` and "name". The subnet and "name" is subject to the same character restrictions described above. The `id` for a `dhcp-hosts` is always in the format `<subnet>.<name>`.

## Kickstart Routes
### Index

List all the kickstart entries.

*SYNTAX:*
```
GET /kickstarts
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular kickstart entry. The `payload` attribute contains the kickstart file's content.

*SYNTAX:*
```
GET /kickstarts/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

*RESPONSE:*

The following is an example response for a successful upload:

```
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
   "data":{
       "type":"kickstarts",
       "id":"<id>",
       "attributes":{
          "size":<size-of-uploaded-file>,
          "system-path":"<content_base_path>/var/www/kickstarts/<id>.ks",
          "uploaded":true,
          "payload":"<content-of-uploaded-kickstart-file>"
       },
       "links":{
          "self":"<app_base_url>/kickstarts/foo"
       },
       "relationships":{
          "blob":{
             "links":{
                "self":"<app_base_url>/kickstarts/foo/relationships/blob",
                "related":"<app_base_url>/kickstarts/foo/blob"
             }
          }
       }
    },
   "jsonapi":{
      "version":"1.0"
   },
   "included":[
   ]
}
```

Kickstarts have a `blob` relationship that can be use to download the file in a raw format. This should be included in the relevant `Legacy` or `Uefi` file.

### Create

TBA

### Update

Updates the kickstart file with the new file content given by the required `payload` attribute.

*BUG*: Currently this path will create kickstart that do not exist. This will be fixed in future release.

*SYNTAX:*
```
PATCH /kickstarts/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "kickstarts",
    "id": "<id>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the kickstart entry and associated file.

*SYNTAX*:
```
DELETE /kickstarts/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Direct Kickstart Download

This is a non `JSON:API` path that returns the raw kickstart file without any `JSON`. This route does not need an authroization token as it is required when the `BIOS` pxeboots.

*SYNTAX:*
```
GET /kickstarts/:id/blob
Content-Type: application/vnd.api+json
Accept: application/octet-stream
```

## Uefi Routes
### Index

List all the Uefi entries.

*SYNTAX:*
```
GET /uefis
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular uefi entry. The `payload` attribute contains the file content.

*SYNTAX:*
```
GET /uefis/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

TBA

### Update

Updates the uefi file with the new file content given by the required `payload` attribute.

*BUG*: Currently this path will create uefi that do not exist. This will be fixed in future release.

*SYNTAX:*
```
PATCH /uefis/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "uefis",
    "id": "<id>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the uefi entry

*SYNTAX*:
```
DELETE /uefis/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

## Legacy Routes
### Index

List all the Legacy entries.

*SYNTAX:*
```
GET /legacies
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular legacy entry. The `payload` attribute contains the file content.

*SYNTAX:*
```
GET /legacies/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

TBA

### Update

Updates the legacy file with the new file content given by the required `payload` attribute.

*BUG*: Currently this path will create legacies that do not exist. This will be fixed in future release.

*SYNTAX:*
```
PATCH /legacies/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "legacies",
    "id": "<id>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the legacies entry and associated file.

*SYNTAX*:
```
DELETE /legacies/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

## Dhcp Subnet Routes
### Index

List all the dhcp subnet entires.

*SYNTAX:*
```
GET /dhcp-subnets
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular dhcp subnet entry. The `payload` attribute contains the file content.

*SYNTAX:*
```
GET /dhcp-subnets/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

TBA

### Update

Updates the DHCP subnet file with the new file content given by the required `payload` attribute.

*BUG*: Currently this path will create subnets that do not exist. This will be fixed in future release.

*SYNTAX:*
```
PATCH /dhcp-subnets/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "dhcp-subnets",
    "id": "<id>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the dhcp subnet entry and associated file.

This will trigger the `DHCP` server to be restarted. See [restarting dhcp](restarting_dhcp.md) for further details.

*SYNTAX*:
```
DELETE /dhcp-subnets/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Fetch Dhcp Hosts

Return the dhcp hosts entries that belong within the subnet.

*SYNTAX:*
```
GET /dhcp-subnets/:id/dhcp-hosts
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

## Dhcp Host Routes
### Index

List all the dhcp host entires.

*SYNTAX:*
```
GET /dhcp-hosts
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular dhcp host entry. The `payload` attribute contains the file content.

*SYNTAX:*
```
GET /dhcp-hosts/:subnet.:name
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

TBA

### Update

Updates the DHCP host file with the new file content given by the required `payload` attribute.

*BUG*: Currently this path will create hosts that do not exist. This will be fixed in future release.


*SYNTAX:*
```
PATCH /dhcp-hosts/:subnet.:name
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "dhcp-hosts",
    "id": "<subnet>.<name>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the dhcp host entry and associated file.

This will trigger the `DHCP` server to be restarted. See [restarting dhcp](restarting_dhcp.md) for further details.

*SYNTAX*:
```
DELETE /dhcp-hosts/:subnet.:name
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Get (Sinja Pluck) the Subnet

Return the subnet entry the host belongs to.

*SYNTAX*:
```
GET /dhcp-hosts/:subnet.:name/dhcp-subnet
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

## Boot Method Routes
### Index

List all the boot method entires.

*SYNTAX:*
```
GET /boot-methods
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular boot method entry. The `kernel` and `initrd` blobs are not returned as part of a show. Instead they must be request specifically using the `GET` blob routes.

*SYNTAX:*
```
GET /boot-methods/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create and Update

TBA - Needs Refactor

### Destroy

Deletes the boot method entry, `kenerl`, and `initrd` files.

*SYNTAX*:
```
DELETE /boot-methods/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Download the Kernel

Directly download the `kernel` binary. This is a non-jsonapi route.

*SYNTAX:*
```
GET /boot-methods/:id/kernel-blob
Content-Type: application/vnd.api+json
Accept: application/octet-stream
Authorization: Bearer <jwt>
```

### Download the Initrd

Directly download the `initrd` binary. This is a non-jsonapi route.

*SYNTAX:*
```
GET /boot-methods/:id/intrd-blob
Content-Type: application/octet-stream
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Upload the Kernel

Upload a new kernel replacing the old file. This is a non-jsonapi route.

*SYNTAX:*
```
POST /boot-methods/:id/kernel-blob
Content-Type: application/octet-stream
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

<the kernel binary should be sent as the POST body>
```

### Upload the Initrd

Upload a new initrd replacing the old file. This is a non-jsonapi route.

*SYNTAX:*
```
POST /boot-methods/:id/initrd-blob
Content-Type: application/octet-stream
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

<the initrd binary should be sent as the POST body>
```

