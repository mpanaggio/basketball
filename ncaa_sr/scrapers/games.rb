#!/usr/bin/env ruby
# coding: utf-8

bad = " "

require "csv"
require "mechanize"

agent = Mechanize.new{ |agent| agent.history.max_size=0 }
agent.user_agent = 'Mozilla/5.0'

base = "http://www.sports-reference.com/cbb/schools"

table_xpath = '//table/tbody/tr'

years = CSV.open("csv/years.csv", "r",
                 {:col_sep => ",", :headers => TRUE})

games = CSV.open("csv/games.csv", "w",
                 {:col_sep => ","})

header = ["year", "school_id", "school_name",
          "row_number", "game_date", "date_url",
          "time", "network",
          "type", "location",
          "opponent", "opponent_url", "opponent_id",
          "conference", "conference_url", "conference_id",
          "outcome", "team_score", "opponent_score",
          "ot", "wins", "losses", "streak",
          "arena"]

games << header

years.each do |school_year|

  year = school_year["year"]
  school_id = school_year["school_id"]
  school_name = school_year["school_name"]
  school_year_url = school_year["school_year_url"]

  if (school_year_url==nil)
    next
  end

#  if (year=="2017")
#    next
#  end
  if (year.to_i<1950)
    next
  end

  url = "#{base}/#{school_id}/#{year}-schedule.html"
  print "Pulling #{school_name} #{year}"

  begin
    page = agent.get(url)
  rescue
    print " - retry"
    retry
  end

  found = 0
  page.parser.xpath(table_xpath).each do |r|

    row = [year,school_id,school_name]
    r.xpath("td|th").each_with_index do |e,i|

      et = e.text.strip.gsub(bad,"") rescue nil
      if (et==nil) or (et.size==0)
        et=nil
      end

      case year.to_i
      when 2015..2017
        case i
        when 1
          if (e.xpath("a").first==nil)
            row += [et, nil]
          else
            row += [et, e.xpath("a").first.attribute("href").to_s]
          end
        when 6,7
          if (e.xpath("a").first==nil)
            row += [et, nil, nil]
          else
            raw_url = e.xpath("a").first.attribute("href").to_s
            id = raw_url.split("/")[-2]
            row += [et, e.xpath("a").first.attribute("href").to_s, id]
          end
        else
          row += [et]
        end
      else
        case i
        when 1
          if (e.xpath("a").first==nil)
            row += [et, nil]
          else
            row += [et, e.xpath("a").first.attribute("href").to_s]
          end
        when 4,5
          if (e.xpath("a").first==nil)
            row += [et, nil, nil]
          else
            raw_url = e.xpath("a").first.attribute("href").to_s
            id = raw_url.split("/")[-2]
            row += [et, e.xpath("a").first.attribute("href").to_s, id]
          end
        else
          row += [et]
        end
      end
    end

    if (year.to_i<2015)
      front = row[0..5]
      back = row[6..-1]
      row = front+[nil,nil]+back
    end

    if (row.size>3) and not(row[4]=="Date")
      found += 1
      games << row
    end

  end

  print " - found #{found}\n"

end

games.close
