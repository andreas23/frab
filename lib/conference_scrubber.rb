class ConferenceScrubber

  DUMMY_MAIL = "root@localhost.localdomain"
  VERBOSE = true

  def initialize(conference,dry_run=false)
    @conference = conference
    @dry_run = dry_run
    @current_conferences = get_last_years_conferences
  end

  def scrub!
    if @dry_run
      puts "dry run, won't change anything!"
    end
    ActiveRecord::Base.transaction do
      scrub_people
      scrub_event_ratings
    end
  end

  private

  def scrub_people
    Person.involved_in(@conference).each { |person|
      unless still_active(person)
        puts "scrubbing #{person.public_name} <#{person.email}>" if VERBOSE
        scrub_person(person)
      end
    }
  end

  def get_last_years_conferences
    Conference.all.select { |c| c.first_day.date.since(1.year) > Time.now }
  end

  def still_active(person)
    @current_conferences.each { |c|
      return true if person.involved_in?(c)
    }
    return false
  end

  def scrub_person(person)
    unless person.email_public or person.include_in_mailings
      person.email = DUMMY_MAIL
    end
    person.phone_numbers.destroy_all unless @dry_run
    person.im_accounts.destroy_all unless @dry_run
    person.note = nil

    unless person.active_in_any_conference?
      puts "scrubbing description of #{person.public_name}" if VERBOSE
      person.abstract = nil
      person.description = nil
      person.avatar.destroy unless @dry_run
      person.links.destroy_all unless @dry_run
    end
    person.save! unless @dry_run
  end

  def scrub_event_ratings
    return if @dry_run
    # keeps events average rating for performance reasons
    EventRating.skip_callback(:save, :after, :update_average)
    EventRating.joins(:event).where(Event.arel_table[:conference_id].eq(@conference.id)).destroy_all
  end

end
