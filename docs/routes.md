# API and Routes Documentation

The API conforms to the [JSON:API](https://jsonapi.org/) specifications with a few additions that have been flagged. The major deviations from the specifications are:

1. There are non-jsonapi blob `POST upload`/`GET download` routes,
2. The model's `id` are alphanumeric, and

These exceptions have been flagged below.

## \*ID Generation

Most API's use server generated auto incrementing integer as id's. In this API, id's are generated client side and are allow to contain any combination of the following characters:
`a-z`, `A-Z`, `0-9`, `-`, and `_`.

The id is otherwise used in the same manner according to the `JSON:API` specifications.

The `dhcp-hosts` and `grubs` files use a compound `id` to denote their relationship. The `dhcp-hosts` id is always in the format `<subnet>.<name>` and the `grubs` id is `<sub-type>.<name>`. The `subnet`, `sub-type`, and `name` is subject to the same character restrains described above.

The `nameds` entries have id's in the format: `<identifier>.[forward|reverse]`. The `identifier` is subject to the same restraints described above. The entry must then be placed either in the `forward` or `reverse` zone.

## Kickstart Routes
### Index

List all the kickstart entries.

*SYNTAX:* routes to the API
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

Kickstarts have a `blob` relationship that can be use to download the file in a raw format. This should be included in the relevant `Legacy` or `Grub` file.

### Create

Upload a new kickstart file to the server. The file's content must be included as the `payload` attribute. A unique client generated `id` is required and must be comprised of `alphanumeric` characters, `-`, and/or `_`.

*SYNTAX:*
```
POST /kickstarts
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

### Update

Updates the kickstart file with the content given by the `payload` attribute. The system file is unaffected unless the `payload` has been included.

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

## Grub Routes
### Index

List all the Grub entries.

*SYNTAX:*
```
GET /grubs
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular grub entry. The `payload` attribute contains the file content.

*SYNTAX:*
```
GET /grubs/:sub_type.:name
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

Upload a new `grub` file to the server. The file's content must be included as the `payload` attribute. A unique client generated `id` is required and must be comprised of the `sub-type` and `name` components. Each component must be `alphanumierc` and may include `-` and `_`.  

The application must be configured with system directory for each grub type. The easiest way to do this is export the path into the environment. The env var key is always in the format: `Grub_<sub-type>_system_dir`.

*SYNTAX:*
```
POST /grubs
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "grubs",
    "id": "<sub-type>.<name>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Update

Updates the grub file with the content given by the `payload` attribute. The system file is unaffected unless the `payload` has been included.

*SYNTAX:*
```
PATCH /grubs/:sub_type.:name
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "grubs",
    "id": "<sub-type>.<name>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Destroy

Deletes the grub entry

*SYNTAX*:
```
DELETE /grubs/:sub_type.:name
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

Upload a new BIOS boot (`legacy`) file to the server. The file's content must be included as the `payload` attribute. A unique client generated `id` is required and must be comprised of `alphanumeric` characters, `-`, and/or `_`.

*SYNTAX:*
```
POST /legacies
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


### Update

Updates the legacy file with the content given by the `payload` attribute. The system file is unaffected unless the `payload` has been included.

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

Upload a new DHCP subnet file to the server. The file's content must be included as the `payload` attribute. A unique client generated `id` is required and must be comprised of `alphanumeric` characters, `-`, and/or `_`.

This action will trigger `DHCP` to be restarted. See [restarting DHCP](restarting_dhcp.md) for further details.

*SYNTAX:*
```
POST /dhcp-subnets
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

### Update

Updates the dhcp subnet file with the content given by the `payload` attribute. The system file is unaffected unless the `payload` has been included.

This action will trigger `DHCP` to be restarted. See [restarting DHCP](restarting_dhcp.md) for further details.

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

Upload a new DHCP host file to the server. The file's content must be included as the `payload` attribute. A unique client generated `id` is required and must be comprised of `alphanumeric` characters, `-`, and/or `_`.

This action will trigger `DHCP` to be restarted. See [restarting DHCP](restarting_dhcp.md) for further details.

*SYNTAX:*
```
POST /dhcp-hosts
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "dhcp-hosts",
    "id": "<id>",
    "attributes": {
      "payload": "<content of uploaded file>"
    }
  }
}
```

### Update

Updates the dhcp host file with the content given by the `payload` attribute. The system file is unaffected unless the `payload` has been included.

This action will trigger `DHCP` to be restarted. See [restarting DHCP](restarting_dhcp.md) for further details.

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

## Named Method Routes
### Index

List all the named entries.

*SYNTAX:*
```
GET /nameds
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Show

Retrieve a particular named entry. The `config-payload` is the component that is included into the main BIND config. It should contain the `zone` statement.

The `zone-payload` contains the zone configuration data. It should be referenced within the `config-payload` `file` statement. The `zone-payload` is stored within the BIND working directory so it can be easily referenced. The relative path from the working directory is given by `zone-relative-path`.

*SYNTAX:*
```
GET /nameds/:identifier.[forward|reverse]
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

### Create

Upload a new Named entry to the server. The `zone` statement should be included as the `config-payload` attribute and will be included into the main BIND config. The zone configuration data must be included as the `zone-payload` attribute and should referenced be referenced within the `config-payload`.

Handy Tip: The relative path to where the `zone-payload` is stored will be returned with the response as the `zone-relative-path` attribute. To get around the chicken and egg scenario this creates, try uploading `config-payload` as an empty string. This will successfully create the entry and return the relative path. Then the `config-payload` can be updated with using the end point below.

This action will trigger the BIND server to validate the configs and restart. The entry unless the server restarts correctly.

*SYNTAX:*
```
POST /nameds
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "nameds",
    "id": "<identifier>.[forward|reverse]",
    "attributes": {
      "config-payload": "<zone statement>",
      "zone-payload": "<zone configuration data>"
    }
  }
}
```

### Update

Update the named entry's "zone statement" or "zone configuration data". This is done by setting the `config-payload` or `zone-payload` attributes respectively. Each file may be updated independently by excluding the other's attribute. Missing attributes are not updated.

This action will trigger the BIND server to validate the configs and restart. The entry unless the server restarts correctly.

*SYNTAX:*
```
PATCH /nameds/:identifier.[forward|reverse]
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "nameds",
    "id": "<identifier>.[forward|reverse]",
    "attributes": {
      "config-payload": "<new zone statement>",
      "zone-payload": "<new zone configuration data>"
    }
  }
}
```

### Destroy

Deletes the named entry and associated zone statement and configuration data.

This action will trigger the BIND server to validate the configs and restart. The entry unless the server restarts correctly.

*SYNTAX*:
```
DELETE /nameds/:identifier.[forward|reverse]
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
```

## Boot Method Routes
### Index

List all the boot method entries.

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

### Create

Upload a new DHCP host file to the server. A unique client generated `id` is required and must be comprised of `alphanumeric` characters, `-`, and/or `_`.

The [kernel](### Upload the Kernel) and [initrd](### Upload the Initrd) images must be uploaded separately after the meta entry has been created.

*SYNTAX:*
```
POST /dhcp-hosts
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

{
  "data": {
    "type": "dhcp-hosts",
    "id": "<id>"
  }
}
```

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

