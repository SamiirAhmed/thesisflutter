<?php

namespace App\Models\campus_env;

use Illuminate\Database\Eloquent\Model;

class CampusEnvironment extends Model
{
    protected $table = 'campus_enviroment';
    protected $primaryKey = 'camp_env_no';

    protected $fillable = [
        'campuses_issues',
        'cat_no',
    ];

    public function complaints()
    {
        return $this->hasMany(CampusEnvComplaint::class, 'camp_env_no', 'camp_env_no');
    }
}
