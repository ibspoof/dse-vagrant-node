require 'net/http'
require "uri"
require 'open-uri'
require 'yaml'

class Downloader

    @@installerDir = './installers/'
    @@baseUrl = "http://downloads.datastax.com/"
    @@dsePath = "enterprise/"
    @@studioPath = "datastax-studio/"
    @@installDseName = "DataStaxEnterprise-[version]-linux-x64-installer.run"
    @@installStudioName = "datastax-studio-[version].tar.gz"
    @@installAgentName = "datastax-agent_[version]_all.deb"
    @@settings ||= {}
    @@dseSettings ||= {}
    @@basicAuth ||= []
    @@getDseVersion ||= ""
    @@getStudioVersion ||= ""
    @@getAgentVersion ||= ""
    @@agentBasePath = "http://debian.datastax.com/enterprise/pool/"

    # set base settings from config.yaml file
    def initialize(settings)
        @@settings = settings
        @@dseSettings = @@settings['vm']['dse']
        @@basicAuth = [ @@dseSettings['install']['username'], @@dseSettings['install']['password'] ]
        @@studioSettings = @@settings['vm']['studio']
        @@agentSettings = @@settings['vm']['dse']["opscenter_agent"]
    end

    # download DSE unattedned installer
    def downloadDSE()
        auto_download = @@dseSettings['install']['auto_download']
        version = @@dseSettings['install']['version']

        if version.match /.*.x/
            getLatestDseVersion(version)
        else
            @@getDseVersion = @@installDseName.gsub("[version]", version)
        end

        targetFile = @@installerDir + @@getDseVersion

        if auto_download != true && !File.exist?(targetFile)
            displayMsg("ERROR: auto_download is turned off and installer file <#{@@getDseVersion}> does not exist." +
                       "\nPlease download unattended installer manually and place in installers directory. " +
                       "\nExiting. \n\n")
            exit!
        end

        if File.exist?(targetFile)
            displayMsg("DSE Installer #{targetFile} exists, skipping download.")
            return
        end

        displayMsg("DSE Installer #{targetFile} does not exist and auto_download enabled.")

        displayMsg("Starting download of DSE Installer. This may take a while...")
        uri = @@baseUrl + @@dsePath + @@getDseVersion
        downloadFile(uri, targetFile)
        displayMsg("Finished downloading DSE installer to #{targetFile}")
    end

    # download Studio
    def downloadStudio()
        install = @@studioSettings['install']
        version = @@studioSettings['version']

        if install != true
            displayMsg("ERROR: Studio install is disabled, skipping download")
            exit!
        end

        if version.match /.*.x/
            getLatestStudioVersion(version)
        else
            @@getStudioVersion = @@installStudioName.gsub("[version]", version)
        end

        targetFile = @@installerDir + @@getStudioVersion

        if File.exist?(targetFile)
            displayMsg("Studio file #{targetFile} exists, skipping download.")
            return
        end

        displayMsg("Studio file #{targetFile} does not exist and auto_download enabled.")

        displayMsg("Starting download of Studio. This may take a while...")
        uri = @@baseUrl + @@studioPath + @@getStudioVersion
        downloadFile(uri, targetFile)
        displayMsg("Finished downloading studio to #{targetFile}")
    end


    # download Studio
    def downloadAgent()
        install = @@agentSettings['install']
        version = @@agentSettings['version']

        if install != true
            displayMsg("ERROR: Agent install is disabled, skipping download")
            exit!
        end

        if version.match /.*.x/
            getLatestAgentVersion(version)
        else
            @@getAgentVersion = @@installAgentName.gsub("[version]", version)
        end

        targetFile = @@installerDir + @@getAgentVersion

        if File.exist?(targetFile)
            displayMsg("Agent install #{targetFile} exists, skipping download.")
            return
        end

        displayMsg("Agent file #{targetFile} does not exist and auto_download enabled.")

        displayMsg("Starting download of Studio. This may take a while...")
        uri = @@agentBasePath + @@getAgentVersion
        downloadFile(uri, targetFile)
        displayMsg("Finished downloading Agent to #{targetFile}")
    end



    # Download file from URI, authentication to target
    def downloadFile(uri, target)
        begin
            File.open(target, "wb") do |saved_file|
                open(uri, :http_basic_authentication => @@basicAuth) do |read_file|
                    saved_file.write(read_file.read)
                end
            end
        rescue OpenURI::HTTPError => error
            case error.io.status[0].to_i
                when 401
                    displayMsg("ERROR: Autentication failed, please check config.yaml username/password.")
                when 404
                    displayMsg("ERROR: Installer version not found on DataStax Academy site, please check version number in config.yaml")
            end
            # delete opened file
            File.delete(target)
            exit!
        end

    end

    def getLatestDseVersion(version)

        case version
        when "5.1.x"
            baseVersion = "5.1."
            regExPath = />DataStaxEnterprise-5.1.(.*)-linux-x64-installer.run<\/a>/
        when "5.0.x"
            baseVersion = "5.0."
            regExPath = />DataStaxEnterprise-5.0.(.*)-linux-x64-installer.run<\/a>/
        else
            baseVersion = "4.8."
            regExPath = />DataStaxEnterprise-4.8.(.*)-linux-x64-installer.run<\/a>/
        end

        begin
            open(@@baseUrl + @@dsePath, :http_basic_authentication => @@basicAuth) do |read_file|
                regMatch = read_file.read.scan regExPath
                lastPointVersion = regMatch.last.first.to_s
                @@getDseVersion = @@installDseName.gsub("[version]", baseVersion << lastPointVersion)
            end
        rescue OpenURI::HTTPError => error
            case error.io.status[0].to_i
                when 401
                    displayMsg("ERROR: Autentication failed, please check config.yaml username/password.")
                when 404
                    displayMsg("ERROR: Installer file not found, please check version number in config.yaml")
            end
        end
    end

    def getLatestStudioVersion(version)

        case version
        when "1.0.x"
            baseVersion = "1.0."
            regExPath = />datastax-studio-1.0.(.*).tar.gz<\/a>/
        else
            baseVersion = "2.0."
            regExPath = />datastax-studio-2.0.(.*).tar.gz<\/a>/
        end

        begin
            open(@@baseUrl + @@studioPath, :http_basic_authentication => @@basicAuth) do |read_file|
                regMatch = read_file.read.scan regExPath
                lastPointVersion = regMatch.last.first.to_s
                @@getStudioVersion = @@installStudioName.gsub("[version]", baseVersion << lastPointVersion)
            end
        rescue OpenURI::HTTPError => error
            case error.io.status[0].to_i
                when 401
                    displayMsg("ERROR: Autentication failed, please check config.yaml username/password.")
                when 404
                    displayMsg("ERROR: Installer file not found, please check version number in config.yaml")
            end
        end
    end

    def getLatestAgentVersion(version)

        case version
        when "6.0.x"
            baseVersion = "6.0."
            regExPath = />datastax-agent_6.0.(.*)_all.deb<\/a>/
        else
            baseVersion = "6.1."
            regExPath = />datastax-agent_6.1.(.*)_all.deb<\/a>/
        end

        begin
            open(@@agentBasePath, :http_basic_authentication => @@basicAuth) do |read_file|
                regMatch = read_file.read.scan regExPath
                lastPointVersion = regMatch.last.first.to_s
                @@getAgentVersion = @@installAgentName.gsub("[version]", baseVersion << lastPointVersion)
            end
        rescue OpenURI::HTTPError => error
            case error.io.status[0].to_i
                when 401
                    displayMsg("ERROR: Autentication failed, please check config.yaml username/password.")
                when 404
                    displayMsg("ERROR: Installer file not found, please check version number in config.yaml")
            end
        end
    end

    # Helper for displaying messages w/ newline
    def displayMsg(msg)
        puts "\n#{msg}"
    end

end


# config = YAML.load_file('./config.yaml')
# d = Downloader.new(config)
# d.downloadDSE()
# d.downloadStudio()
# d.downloadAgent()
