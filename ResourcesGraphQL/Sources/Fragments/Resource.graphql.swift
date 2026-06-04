// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public struct Resource: ResourcesGraphQL.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment Resource on resources { __typename id updated_at created_at documentName documentNumber s3_key thumbnail_s3_key }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { ResourcesGraphQL.Objects.Resources }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("id", ResourcesGraphQL.Uuid.self),
    .field("updated_at", ResourcesGraphQL.Timestamptz.self),
    .field("created_at", ResourcesGraphQL.Timestamptz.self),
    .field("documentName", String.self),
    .field("documentNumber", String.self),
    .field("s3_key", String.self),
    .field("thumbnail_s3_key", String.self),
  ] }

  public var id: ResourcesGraphQL.Uuid { __data["id"] }
  public var updated_at: ResourcesGraphQL.Timestamptz { __data["updated_at"] }
  public var created_at: ResourcesGraphQL.Timestamptz { __data["created_at"] }
  public var documentName: String { __data["documentName"] }
  public var documentNumber: String { __data["documentNumber"] }
  public var s3_key: String { __data["s3_key"] }
  public var thumbnail_s3_key: String { __data["thumbnail_s3_key"] }
}
