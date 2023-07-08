import Vapor

let dir = NSHomeDirectory().split(separator: "/")[1]
var kApp: Application!

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
    
    readFile()
    
    kApp = app
    app.http.server.configuration.port = 1999
    let vc = CoreViewController()
    vc.configModels()
}


func readFile() {
    let filepath = "/Users/\(dir)/Desktop/file.txt"
    let data = try? Data(contentsOf: URL(fileURLWithPath: filepath))
    print(data)
}


