require 'nokogiri'
require 'rest_client'

FIELDS = ['id', 'url', 'country', 'name', 'full_location', 'website', 'type', 'sectors']
BASE_URL = 'https://www.iasp.ws/our-members/directory/@'

def get_detail(url, id)
    res = RestClient.get(url)
    raw_page = res.body
    page = Nokogiri::HTML(raw_page)
    details = {
        id: id,
        url: url,
        country: nil,
        name: nil,
        full_location: nil,
        website: nil,
        type: nil,
        sectors: []
    }
    page.css(".mergefield").each do |f|
        vdlabel = f.css(".vdlabel").text
        vdcon = f.css(".vdcontent").text
        if vdlabel.include?('Location')
            details[:full_location] = vdcon
            matches = vdcon.match(/(.*), (.*)/)
            if matches
                details[:country] = matches[2]
            end
        end
        if vdlabel.include?('Name') and details[:name] == nil
            details[:name] = vdcon
        end
        if vdlabel.include?('Website')
            website_anchor = f.css('.vdcontent a')
            if !website_anchor.empty?
                details[:website] = website_anchor.attr('href').value
            end
        end
        if vdlabel.include?('Type')
            details[:type] = vdcon
        end
        if vdlabel.include?('Main technology sectors')
            f.css('.vdcontent .vdcontent').each do |s|
                details[:sectors] << s.text
            end
        end

    end

    return details
end

# Taken from: https://www.iasp.ws/our-members/directory
page = Nokogiri::HTML(open("snapshot_30072019.html"))
members = page.css(".member-item")

members.each do |d|
    href = d.attr('href')
    splits = href.split('/')
    id = splits[3].gsub!("@", "").to_i
    url = BASE_URL + id.to_s
    name = d.css('.vdcontent').text.chomp.encode('utf-8')
    details = get_detail(url, id)
    puts details.values.join("\t")
end