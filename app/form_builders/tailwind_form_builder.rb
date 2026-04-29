class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  FIELD_CLASSES = 'mt-1 block w-full rounded-lg border border-gray-300 bg-white py-2 px-3 text-gray-900 placeholder-gray-400 focus:border-amber-600 focus:ring-2 focus:ring-amber-200 transition'.freeze
  LABEL_CLASSES = 'block text-sm font-medium text-gray-700'.freeze
  SUBMIT_CLASSES = 'inline-flex items-center justify-center rounded-lg bg-amber-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-amber-700 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2 transition'.freeze

  %i[text_field email_field number_field phone_field password_field search_field url_field text_area select collection_select date_select datetime_select time_select].each do |field_type|
    define_method(field_type) do |method, *args, **options|
      options = args.extract_options!.merge(options)
      options[:class] = [options[:class], FIELD_CLASSES].compact.join(' ')
      super(method, *args, options)
    end
  end

  def label(method, text = nil, options = {}, &block)
    options[:class] = [options[:class], LABEL_CLASSES].compact.join(' ')
    super(method, text, options, &block)
  end

  def submit(value = nil, options = {})
    options[:class] = [options[:class], SUBMIT_CLASSES].compact.join(' ')
    super(value, options)
  end
end
