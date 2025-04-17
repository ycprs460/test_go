{
  "id": "rest-api-workflow",
  "version": "1.0",
  "specVersion": "0.8",
  "name": "REST API Invocation Workflow",
  "description": "A workflow that invokes a REST API and processes the response.",
  
  "inputSchema": {
    "type": "object",
    "properties": {
      "apiUrl": {
        "type": "string",
        "description": "The URL of the REST API to invoke."
      },
      "apiKey": {
        "type": "string",
        "description": "The API key for authentication (optional)."
      }
    },
    "required": ["apiUrl"]
  },

  "outputSchema": {
    "type": "object",
    "properties": {
      "status": {
        "type": "string",
        "description": "The status of the workflow execution."
      },
      "data": {
        "type": "object",
        "description": "The processed data from the API response."
      }
    }
  },

  "states": [
    {
      "name": "InvokeRESTAPI",
      "type": "operation",
      "actionMode": "sequential",
      "actions": [
        {
          "name": "CallAPI",
          "functionRef": {
            "refName": "callRestApiFunction",
            "arguments": {
              "method": "GET",
              "url": "${ .apiUrl }",
              "headers": {
                "Authorization": "Bearer ${ .apiKey }"
              }
            }
          }
        }
      ],
      "transition": "ProcessResponse"
    },
    {
      "name": "ProcessResponse",
      "type": "operation",
      "actionMode": "sequential",
      "actions": [
        {
          "name": "ExtractData",
          "functionRef": {
            "refName": "processDataFunction",
            "arguments": {
              "rawData": "${ .CallAPI.response.body }"
            }
          }
        }
      ],
      "transition": "DetermineNextStep"
    },
    {
      "name": "DetermineNextStep",
      "type": "switch",
      "dataConditions": [
        {
          "condition": "${ .ExtractData.status == 'success' }",
          "transition": "SuccessState"
        },
        {
          "condition": "${ .ExtractData.status == 'error' }",
          "transition": "ErrorState"
        }
      ]
    },
    {
      "name": "SuccessState",
      "type": "operation",
      "end": {
        "terminate": true,
        "produceEvents": [
          {
            "eventRef": "successEvent",
            "data": "${ .ExtractData.data }"
          }
        ]
      }
    },
    {
      "name": "ErrorState",
      "type": "operation",
      "end": {
        "terminate": true,
        "produceEvents": [
          {
            "eventRef": "errorEvent",
            "data": "${ .ExtractData.error }"
          }
        ]
      }
    }
  ],

  "functions": [
    {
      "name": "callRestApiFunction",
      "type": "rest",
      "metadata": {
        "method": "GET",
        "url": "${ .url }",
        "headers": "${ .headers }"
      }
    },
    {
      "name": "processDataFunction",
      "type": "custom",
      "metadata": {
        "process": "extractAndValidateData"
      }
    }
  ],

  "events": [
    {
      "name": "successEvent",
      "type": "success",
      "source": "internal",
      "dataOnly": true
    },
    {
      "name": "errorEvent",
      "type": "error",
      "source": "internal",
      "dataOnly": true
    }
  ]
}
