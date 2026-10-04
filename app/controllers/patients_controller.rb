class PatientsController < ApplicationController
  def index
    @pagy, @patients = pagy(:offset, Patient.where(is_current: 1).includes(:address).order(:patient_health_identifier_number).all, limit: 20)
  end

  def show
  end
end
