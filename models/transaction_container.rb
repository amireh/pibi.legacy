module TransactionContainer

  def latest_transactions(q = {}, t = nil)
    transactions_in(nil, q)
    # transactions.all({ :occured_on.gte => Timetastic.this.month, :occured_on.lt => Timetastic.next.month }.merge(q))
  end

  [ :daily, :monthly, :yearly ].each { |period|
    # Defines three methods that return the transactions for each time domain;
    # a year, a month, or a day. The range begins at the *start* of the domain,
    # NOT relative to the current time.
    #
    # The methods can accept two arguments:
    # => a date (Time) object that will be used as an anchor (defaults to Time.now)
    # => a query filter hash (defaults to {})
    #
    # Methods:
    # => yearly_transactions(d,q)
    # => monthly_transactions(d,q)
    # => daily_transactions(d,q)
    domain = period.to_s.gsub('ly', '')
    define_method(:"#{period}_transactions") { |d = Time.now, q = {}|
      transies = []
      # is this thread-safe?
      Timetastic.fixate(d) {
        transies = transactions_in({
          :begin => Timetastic.this.send(domain),
          :end => Timetastic.next.send(domain)
        }, q)
      }
      transies
    }

    # Defines three methods that return the amount of recurring expenses
    # that are billed throughout the time domain; year, month, or day.
    define_method(:"#{period}_expenses") {
      expenses = 0.0
      recurrings.all({ frequency: period, active: true }).each { |t| expenses = t + expenses }
      expenses
    }

    # Defines three methods that return the *balance* of a given
    # collection of transactions.
    #
    # The first argument can be either a collection, or a date which
    # will be used to pull the period transaction collection and then
    # calculate the balance for that.
    #
    # So, you can get the yearly balance in two ways:
    # => yearly_balance(Time.new(2012, 1, 1))
    # => yearly_balance(my_yearly_transies)
    define_method(:"#{period}_balance") { |in_c, q = {}|
      c = []
      if in_c.is_a?(DataMapper::Collection)
        c = in_c
      elsif in_c.is_a?(Time) || in_c.is_a?(Date)
        c = self.send(:"#{period}_transactions", in_c, q)
      else
        raise ArgumentError.new("First argument to #{period}_balance must be " +
          "either a DataMapper::Collection of Transaction objects, or a Time object.")
      end

      balance_for c
    }
  }

  def transactions_in(range = {}, q = {})
    range ||= {
      :begin => Timetastic.this.month,
      :end => Timetastic.next.month
    }

    transactions.all({
      :occured_on.gte => range[:begin],
      :occured_on.lt => range[:end],
      :type.not => Recurring
    }.merge(q))
  end

  def balance_for(collection)
    balance = 0.0
    collection.each { |tx| balance = tx + balance }
    balance
  end

end