<?php

namespace App\Models\campus_env;

use Illuminate\Database\Eloquent\Model;
use App\Models\Student;

class CampusEnvComplaint extends Model
{
    protected $table = 'campus_envo_complaints';
    protected $primaryKey = 'cmp_env_com_no';

    protected $fillable = [
        'camp_env_no',
        'title',
        'images',
        'description',
        'std_id',
    ];

    public function issueType()
    {
        return $this->belongsTo(CampusEnvironment::class, 'camp_env_no', 'camp_env_no');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'std_id', 'std_id');
    }

    public function assignments()
    {
        return $this->hasMany(CampusEnvAssign::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }

    public function tracking()
    {
        return $this->hasMany(CampusEnvTracking::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }

    public function supports()
    {
        return $this->hasMany(CampusEnvSupport::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }
}
