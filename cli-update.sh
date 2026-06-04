# Use the same version of the Apollo library that you are using.
CLI_URL="https://github.com/apollographql/apollo-ios/releases/download/1.19.0/apollo-ios-cli.tar.gz"

curl -L $CLI_URL -o apollo-ios-cli.tar.gz
tar -xzf apollo-ios-cli.tar.gz
chmod +x apollo-ios-cli
rm apollo-ios-cli.tar.gz

./apollo-ios-cli fetch-schema

./apollo-ios-cli generate
