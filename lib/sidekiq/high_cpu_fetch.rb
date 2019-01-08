require 'sidekiq/fetch'

class Sidekiq::HighCpuFetch < Sidekiq::BasicFetch
  class QueueCounter
    include Singleton

    attr_accessor :max_concurrency
    attr_accessor :watched_queues

    def initialize
      @lock = Mutex.new
      @hash = Hash.new(0)
    end

    def started(queue)
      @lock.synchronize do
        @hash[queue] += 1
      end
    end

    def done(queue)
      @lock.synchronize do
        @hash[queue] -= 1
      end
    end

    def count(queue)
      @lock.synchronize do
        @hash[queue]
      end
    end

    def exceeded_queues
      return if !@watched_queues || !@max_concurrency

      @lock.synchronize do
        current = @watched_queues.map do |q|
          @hash[q]
        end.sum

        if current < @max_concurrency
          []
        else
          @watched_queues
        end
      end
    end
  end

  def initialize(*args)
    @queue_counter = Sidekiq::HighCpuFetch::QueueCounter.instance
    super(*args)
  end

  def retrieve_work
    queues = (@queues.shuffle - @queue_counter.exceeded_queues).uniq
    queues << TIMEOUT
    data = Sidekiq.redis { |conn| conn.brpop(*queues) }
    if data
      unit_of_work = UnitOfWork.new(*data)
      @queue_counter.started(unit_of_work.queue)
    end
    unit_of_work
  end
end

class Sidekiq::DoneMiddleware
  def call(worker, job, queue)
    yield
  ensure
    Sidekiq::HighCpuFetch::QueueCounter.instance.done("queue:#{queue}")
  end
end
