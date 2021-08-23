#!/bin/bash

set -e

if [[ -z "${4}" ]] ; then
    printf 'resource group: ' && read RESOURCE_GROUP
    printf 'storage account name: ' && read STOR_AC
    printf 'log analytics resource group: ' && read LAW_RG
    printf 'log analytics workspace: ' && read LAW_NAME
else
    RESOURCE_GROUP="${1}"
    STOR_AC="${2}"
    LAW_RG="${3}"
    LAW_NAME="${4}"
fi

STOR_AC_ID=`az storage account show \
--name ${STOR_AC} \
--resource-group ${RESOURCE_GROUP} \
--query id --output tsv`

LOGANALYTICS_ID=`az monitor log-analytics workspace show \
--resource-group ${LAW_RG} \
--workspace-name ${LAW_NAME} \
--query id --output tsv`

BLOB_ID="${STOR_AC_ID}/blobServices/default"
FILES_ID="${STOR_AC_ID}/fileServices/default"
QUEUE_ID="${STOR_AC_ID}/queueServices/default"
TABLES_ID="${STOR_AC_ID}/tableServices/default"

#storage account defaults
az monitor diagnostic-settings create \
--resource ${STOR_AC_ID} --name "loganalytics" \
--workspace ${LOGANALYTICS_ID} --metrics \
'[
  {
    "category": "Transaction",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  },
  {
    "category": "Capacity",
    "enabled": false,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  }
]' | jq

#blob defaults
az monitor diagnostic-settings create \
--resource ${BLOB_ID} --name "loganalytics" \
--workspace ${LOGANALYTICS_ID} --metrics \
'[
  {
    "category": "Capacity",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  },
  {
    "category": "Transaction",
    "enabled": false,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  }
]' --logs \
'[
  {
    "category": "StorageRead",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageWrite",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageDelete",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  }
]' | jq

#files defaults
az monitor diagnostic-settings create \
--resource ${FILES_ID} --name "loganalytics" \
--workspace ${LOGANALYTICS_ID} --metrics \
'[
  {
    "category": "Capacity",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  },
  {
    "category": "Transaction",
    "enabled": false,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  }
]' --logs \
'[
  {
    "category": "StorageRead",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageWrite",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageDelete",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  }
]' | jq

#queue defaults
az monitor diagnostic-settings create \
--resource ${QUEUE_ID} --name "loganalytics" \
--workspace ${LOGANALYTICS_ID} --metrics \
'[
  {
    "category": "Capacity",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  },
  {
    "category": "Transaction",
    "enabled": false,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  }
]' --logs \
'[
  {
    "category": "StorageRead",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageWrite",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageDelete",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  }
]' | jq

#tables defaults
az monitor diagnostic-settings create \
--resource ${TABLES_ID} --name "loganalytics" \
--workspace ${LOGANALYTICS_ID} --metrics \
'[
  {
    "category": "Capacity",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  },
  {
    "category": "Transaction",
    "enabled": false,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    },
    "timeGrain": null
  }
]' --logs \
'[
  {
    "category": "StorageRead",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageWrite",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  },
  {
    "category": "StorageDelete",
    "enabled": true,
    "retentionPolicy": {
      "days": 0,
      "enabled": false
    }
  }
]' | jq
