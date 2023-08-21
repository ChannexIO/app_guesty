defmodule Guesty.DTO.Schemes.ARI do
  @schema %{
    "type" => "object",
    "properties" => %{
      "propertyid" => %{
        "type" => ["integer", "string"]
      },
      "room_id" => %{
        "type" => ["integer", "string"]
      },
      "rate_id" => %{
        "type" => ["integer", "string"]
      },
      "currency" => %{
        "type" => "string"
      },
      "trackingId" => %{
        "type" => "string"
      },
      "data" => %{
        "type" => "array",
        "minItems" => 1,
        "items" => %{
          "type" => "object",
          "properties" => %{
            "from_date" => %{
              "type" => "string",
              "format" => "date"
            },
            "to_date" => %{
              "type" => "string",
              "format" => "date"
            },
            "inventory" => %{
              "type" => ["integer", "string"],
              "pattern" => "^[0-9]+$"
            },
            "stopsell" => %{
              "type" => "string",
              "enum" => ["N", "Y"]
            },
            "minstay" => %{
              "type" => ["integer", "string"],
              "pattern" => "^[0-9]+$"
            },
            "maxstay" => %{
              "type" => ["integer", "string"],
              "pattern" => "^[0-9]+$"
            },
            "cta" => %{
              "type" => "string",
              "enum" => ["N", "Y"]
            },
            "ctd" => %{
              "type" => "string",
              "enum" => ["N", "Y"]
            },
            "amountAftertax" => %{
              "type" => "object",
              "properties" => %{
                "obp" => %{
                  "type" => "object",
                  "properties" => %{
                    "person1" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person2" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person3" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person4" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person5" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person6" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person7" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person8" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    }
                  }
                }
              }
            },
            "amountBeforetax" => %{
              "type" => "object",
              "properties" => %{
                "obp" => %{
                  "type" => "object",
                  "properties" => %{
                    "person1" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person2" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person3" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person4" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person5" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person6" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person7" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    },
                    "person8" => %{
                      "type" => ["integer", "string"],
                      "pattern" => "^[0-9.]+$"
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "required" => ["room_id", "rate_id", "propertyid", "data"]
  }

  def get(), do: ExJsonSchema.Schema.resolve(@schema)
end
