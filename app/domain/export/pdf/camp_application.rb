# encoding: utf-8

#  Copyright (c) 2015 Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Export::Pdf
  class CampApplication

    include Translatable

    attr_reader :camp, :pdf, :data

    delegate :text, :font_size, :move_down, :text_box, :cursor, :table,
             to: :pdf
    delegate :t, :l, to: I18n

    def initialize(camp)
      @camp = camp
      @data = CampApplicationData.new(camp)
    end

    def render
      @pdf = Prawn::Document.new(page_size: 'A4',
                                 page_layout: :portrait,
                                 margin: 2.cm)
      pdf.font_size 10

      render_sections

      pdf.number_pages(t('event.participations.print.page_of_pages'),
                       at: [0, 0],
                       align: :right,
                       size: 9)
      pdf.render
    end

    def filename
      "TODO.pdf"
    end

    private

    def render_sections
      @section_count = 0
      render_title
      render_group
      render_leader
      render_assistant_leaders
      render_camp
      render_j_s
      render_state
      render_abteilungsleitung
      render_coach
    end

    def render_title
      font_size(20) do
        text translate('title', camp: camp.name), style: :bold
      end
      move_down_line
    end

    def render_group
      section('group_header') do
        with_label('abteilung', data.abteilung_name)
        with_label('einheit', data.einheit_name) if data.einheit_name
        render_expected_participant_table
      end
    end

    def render_expected_participant_table
      move_down_line
      text translate('expected_participants')
      move_down_line
      cells = []
      cells << data.expected_participant_table_header
      cells << data.expected_participant_table_row(:f)
      cells << data.expected_participant_table_row(:m)
      table(cells, cell_style: { align: :center, border_width: 0.25, width: 50})
    end

    def render_leader
      section('leader_header') do
        leader = data.camp_leader
        if leader
          with_label('name', leader)
          with_label('address', leader.address)
          with_label('zip_town', [leader.zip_code, leader.town].compact.join(' '))
          with_label('birthday', leader.birthday.presence && l(leader.birthday))
          with_label('qualifications', data.active_qualifications(leader))
        else
          text_nobody
        end
      end
    end

    def render_assistant_leaders
      section('assistant_leaders_header') do
        cells = data.camp_assistant_leaders.collect do |person|
          [person.to_s, person.birthday.try(:year).to_s, data.active_qualifications(person)]
        end
        if cells.present?
          table(cells, width: 500,
                cell_style: { border_width: 0.25 },
                column_widths: [210, 40, 250])
        else
          text_nobody
        end
      end
    end

    def text_nobody
      text "(#{t('global.nobody')})"
    end

    def text_no_entry
      text "(#{t('global.no_entry')})"
    end

    def render_camp
      section('camp') do
        sub_section('camp_dates') do
          render_dates
        end
        sub_section('camp_location') do
          render_location
        end
      end
    end

    def render_dates
      camp.dates.each do |d|
        labeled_value(d.label, d.duration.to_s)
      end
    end

    def render_location
      labeled_camp_attr(:canton)
      labeled_camp_attr(:location)
      labeled_camp_attr(:coordinates)
      labeled_camp_attr(:altitude)
      labeled_camp_attr(:landlord)
      labeled_camp_attr(:landlord_permission_obtained)
    end

    def render_j_s
      section('j_s') do
        labeled_camp_attr(:j_s_kind)
        labeled_camp_attr(:advisor_mountain_security)
        labeled_camp_attr(:advisor_water_security)
        labeled_camp_attr(:advisor_snow_security)
      end
    end

    def render_state
    end

    def render_abteilungsleitung
    end

    def render_coach

    end

    def section(header)
      @section_count += 1
      heading { text "#{@section_count}. #{translate(header)}", style: :bold }
      move_down_line
      yield
      2.times { move_down_line }
    end

    def sub_section(header)
      heading { text translate(header), style: :bold, size: 10 }
      move_down_line
      yield
      move_down_line
    end

    def heading
      font_size(14) { yield }
    end

    def with_label(key, value)
      label = translate(key)
      labeled_value(label, value)
    end

    def labeled_camp_attr(attr)
      value = data.camp_attr_value(attr)
      return unless value.present?
      label = data.t_camp_attr(attr.to_s)
      labeled_value(label, value)
      move_down_if_multiline(value)
    end

    def move_down_if_multiline(value)
      count = value.scan("\n").count
      count.times { move_down_line } if count > 0
    end

    def labeled_value(label, value)
      text_box(label, at: [0, cursor], width: 180, style: :italic)
      text_box(value.to_s, at: [180, cursor])
      move_down_line
    end

    def move_down_line(line = 12)
      move_down(line)
    end

  end
end
