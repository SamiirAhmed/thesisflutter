<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Seed Roles first (Needed for users FK)
        DB::table('roles')->updateOrInsert(['role_id' => 1], [
            'role_name' => 'Admin',
            'description' => 'System Administrator',
            'status' => 'Active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('roles')->updateOrInsert(['role_id' => 2], [
            'role_name' => 'Student',
            'description' => 'University Student',
            'status' => 'Active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Insert admin user
        if (!DB::table('users')->where('username', 'admin')->exists()) {
            DB::table('users')->insert([
                'role_id' => 1,
                'full_name' => 'System Admin',
                'username' => 'admin',
                'password_hash' => hash('sha256', 'password123'),
                'status' => 'Active',
                'Accees_channel' => 'BOTH',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $this->command->info('Admin user created successfully!');
        } else {
            $this->command->info('User admin already exists!');
        }

        $this->command->info('Seeding completed!');
    }
}
