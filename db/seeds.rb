# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.where(username: 'superadmin').first_or_create(username: 'superadmin', password: 'pwd12345', name: 'superadmin', role: 'superadmin')
unit = Unit.where(no: '10000000').first_or_create(name: '招行', short_name: '招行', level:1)
User.where(username: 'unitadmin').first_or_create(username: 'unitadmin', password: 'unitadmin12345', name: '机构管理员', role: 'unitadmin', unit_id: unit.id, email: 'email@email.com')
User.where(username: 'user').first_or_create(username: 'user', password: 'user12345', name: '普通用户', role: 'user', unit_id: unit.id)
