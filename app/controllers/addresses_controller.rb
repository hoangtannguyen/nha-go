class AddressesController < ApplicationController
  # Trả danh sách phường/xã của một tỉnh cho ô select bên checkout.
  # Dữ liệu nằm sẵn trong app nên không gọi ra ngoài.
  def wards
    province_code = params[:province_code]

    if VietnamAddress.province_code?(province_code)
      render json: {
        province: VietnamAddress.province_name(province_code),
        wards: VietnamAddress.wards(province_code).map { |ward| { code: ward[:code], name: ward[:name] } }
      }
    else
      render json: { province: nil, wards: [] }
    end
  end
end
